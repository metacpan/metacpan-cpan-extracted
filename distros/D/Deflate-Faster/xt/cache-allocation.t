use strict;
use warnings;
use Test::More;
use Config;
use File::Temp;
use Text::ParseWords qw(shellwords);

plan skip_all => 'Allocation fault injection requires Linux and glibc' if $^O ne 'linux';

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $source = "$dir/fail-cache.c";
my $library = "$dir/fail-cache.so";
open my $fh, '>', $source or die $!;
print {$fh} <<'C';
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <dlfcn.h>
#include <errno.h>
#include <stddef.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef __GLIBC__
#error "glibc required"
#endif
extern void *__libc_calloc(size_t, size_t);
extern void __libc_free(void *);
static int failed = 0;
static pthread_key_t foreign_key;
static int foreign_value;
static int foreign_ready = 0;
static void *registered_cache = NULL;
static pthread_key_t registered_key;
static int cache_freed = 0;

static int fault_is(const char *name)
{
    const char *fault = getenv("DEFLATE_FASTER_CACHE_FAULT");
    return fault && strcmp(fault, name) == 0;
}

static int module_address(const void *address)
{
    Dl_info info;
    return address && dladdr(address, &info) && info.dli_fname &&
           strstr(info.dli_fname, "/Deflate/Faster/Faster.so");
}

__attribute__((constructor)) static void reserve_foreign_key(void)
{
    if (fault_is("key") && pthread_key_create(&foreign_key, NULL) == 0 &&
        pthread_setspecific(foreign_key, &foreign_value) == 0) {
        foreign_ready = 1;
    }
}

__attribute__((destructor)) static void check_foreign_key(void)
{
    if (fault_is("key")) {
        puts(foreign_ready && pthread_getspecific(foreign_key) == &foreign_value ?
             "foreign_key=ok" : "foreign_key=changed");
    }
    if (fault_is("cleanup")) {
        puts(registered_cache && !cache_freed &&
             pthread_getspecific(registered_key) == registered_cache ?
             "cleanup=ok" : "cleanup=invalid");
    }
}

void *calloc(size_t count, size_t size)
{
    if (!failed && fault_is("allocation") &&
        module_address(__builtin_return_address(0))) {
        failed = 1;
        errno = ENOMEM;
        return NULL;
    }
    return __libc_calloc(count, size);
}

void free(void *ptr)
{
    if (ptr && ptr == registered_cache) {
        cache_freed = 1;
    }
    __libc_free(ptr);
}

int pthread_key_create(pthread_key_t *key, void (*destructor)(void *))
{
    int (*next_call)(pthread_key_t *, void (*)(void *)) =
        dlsym(RTLD_NEXT, "pthread_key_create");
    if (!failed && fault_is("key") && module_address((const void *)destructor)) {
        failed = 1;
        return EAGAIN;
    }
    return next_call(key, destructor);
}

int pthread_setspecific(pthread_key_t key, const void *value)
{
    int (*next_call)(pthread_key_t, const void *) = dlsym(RTLD_NEXT, "pthread_setspecific");
    if (!failed && fault_is("registration") && value &&
        module_address(__builtin_return_address(0))) {
        failed = 1;
        return ENOMEM;
    }
    if (fault_is("cleanup") && module_address(__builtin_return_address(0))) {
        if (value) {
            registered_cache = (void *)value;
            registered_key = key;
        }
        else if (!failed) {
            failed = 1;
            return ENOMEM;
        }
    }
    return next_call(key, value);
}
C
close $fh or die $!;
my @cc = shellwords($Config{cc});
my @ccflags = shellwords($Config{ccflags});
system(@cc, @ccflags, '-shared', '-fPIC', '-O2', $source, '-ldl', '-pthread', '-o', $library) == 0
    or plan skip_all => 'A compiler supporting allocation fault injection is required';

for my $case (['allocation', 'Failed to allocate engine cache'],
              ['key', 'Failed to allocate engine cache key'],
              ['registration', 'Failed to register engine cache']) {
    my ($fault, $error) = @$case;
    for my $call ('Deflate::Faster::gzip("payload")',
                 'Deflate::Faster::gunzip(pack("H*", "1f8b080000000000000303000000000000000000"))') {
        my $code = 'eval { ' . $call . ' }; print "caught=$@";' .
                   'my $retry = eval { ' . $call . ' }; die $@ if $@;' .
                   'print defined($retry) ? "retry=ok\n" : "retry=failed\n";';
        local $ENV{LD_PRELOAD} = $library;
        local $ENV{DEFLATE_FASTER_CACHE_FAULT} = $fault;
        open my $child, '-|', $^X, '-Mblib', '-MDeflate::Faster', '-e', $code or die $!;
        my $output = do { local $/; <$child> };
        my $closed = close $child;
        ok($closed, "$fault failure is catchable without a native crash");
        like($output, qr/caught=\Q$error\E.*\nretry=ok\n/s,
             "engine cache recovers after $fault failure");
        if ($fault eq 'key') {
            like($output, qr/foreign_key=ok/, "key failure preserves another component's value");
        }
    }
}

{
    local $ENV{LD_PRELOAD} = $library;
    local $ENV{DEFLATE_FASTER_CACHE_FAULT} = 'cleanup';
    open my $child, '-|', $^X, '-Mblib', '-MDeflate::Faster', '-e',
         'Deflate::Faster::gzip("payload")' or die $!;
    my $output = do { local $/; <$child> };
    ok(close($child), "cache cleanup failure does not cause a native crash");
    like($output, qr/cleanup=ok/, "cache remains valid when its thread value cannot be cleared");
}

done_testing();
