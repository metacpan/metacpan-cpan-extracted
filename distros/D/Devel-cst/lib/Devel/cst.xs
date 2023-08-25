#include <signal.h>
#include <execinfo.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int stack_depth;

static void handler(int signo, siginfo_t* info, void* context) {
	psiginfo(info, NULL);

	void** buffer = alloca(sizeof(void*) * stack_depth);
	size_t len = backtrace(buffer, stack_depth);
	/* Skip signal handler itself */
	backtrace_symbols_fd(buffer + 2, len - 2, 2);

	raise(signo);
}

static void* volatile altstack_ptr = NULL;

static void stack_destroy() {
	stack_t altstack;
	altstack.ss_sp = NULL;
	altstack.ss_size = 0;
	altstack.ss_flags = SS_DISABLE;
	sigaltstack(&altstack, NULL);
	free(altstack_ptr);
}

static void set_signalstack() {
	size_t stacksize = 2 * SIGSTKSZ;
	altstack_ptr = calloc(stacksize, 1);
	stack_t altstack;
	altstack.ss_sp = altstack_ptr;
	altstack.ss_size = stacksize;
	altstack.ss_flags = 0;
	sigaltstack(&altstack, NULL);
	atexit(stack_destroy);
}

static const int signals_normal[] = { SIGILL, SIGFPE, SIGTRAP, SIGABRT, SIGQUIT, SIGBUS };

static void set_handlers() {
	struct sigaction action;
	int i;
	action.sa_sigaction = handler;
	action.sa_flags     = SA_RESETHAND | SA_NODEFER | SA_SIGINFO;
	sigemptyset(&action.sa_mask);
	for (i = 0; i < sizeof signals_normal / sizeof *signals_normal; i++)
		sigaction(signals_normal[i], &action, NULL);
	action.sa_flags |= SA_ONSTACK;
	sigaction(SIGSEGV, &action, NULL);
}

MODULE = Devel::cst        				PACKAGE = Devel::cst

BOOT:
	/* preload libgcc_s by getting a stacktrace early */
	void** buffer = alloca(sizeof(void*) * 20);
	size_t len = backtrace(buffer, 20);

void import(SV* package, size_t depth = 20)
	CODE:
	if (!altstack_ptr) {
		set_signalstack();
		stack_depth = depth;
		set_handlers();
	}

MODULE = Devel::cst        				PACKAGE = Devel::CStacktrace

void stacktrace(size_t depth)
	PPCODE:
	void** buffer;
	Newx(buffer, depth, void*);
	size_t len = backtrace(buffer, depth);
	char** values = backtrace_symbols(buffer, len);
	int i;
	for (i = 0; i < len; i++)
		mXPUSHp(values[i], strlen(values[i]));
	free(values);
