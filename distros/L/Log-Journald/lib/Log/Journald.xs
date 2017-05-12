#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/uio.h>

/* We determine our location from the Perl code instead. */
#define SD_JOURNAL_SUPPRESS_LOCATION
#include <systemd/sd-journal.h>

/* Extra fields to be added at the end of each log vector. */
enum {
	CODE_FILE,
	CODE_LINE,
	EXTRA_CNT
};

/* Fill in an iovec entry with a formatted string. */
#define IOVEC_FMT(vec, ...) do {					\
	(vec).iov_len = asprintf ((char **)&(vec).iov_base, __VA_ARGS__); \
	if ((vec).iov_len == -1)					\
		(vec).iov_base = NULL;					\
} while(0)

/* Allocate iovec for given number of fields, automatically filling extra
 * entries at the end. */
static struct iovec *
alloc_iovec (items)
	const int items;
{
	struct iovec *logv;

	logv = malloc(sizeof (struct iovec) * (items + EXTRA_CNT));
	if (logv == NULL)
		return NULL;

	IOVEC_FMT(logv[items + CODE_FILE], "CODE_FILE=%s",
		OutCopFILE(PL_curcop));
	IOVEC_FMT(logv[items + CODE_LINE], "CODE_LINE=%d",
		CopLINE(PL_curcop));

	return logv;
}

/* Send the vector to the journal and deallocate the extra entries we've
 * allcoated in alloc_iovec(). Handle errors in the manner more typical to
 * Perl (return -1 & set errno as opposed to returning -errno. */
static int
submit_iovec (logv, items)
	struct iovec *logv;
	const int items;
{
	int err;

	err = sd_journal_sendv(logv, items + EXTRA_CNT);
	free(logv[items + CODE_FILE].iov_base);
	free(logv[items + CODE_LINE].iov_base);
	if (err) {
		errno = -err;
		return -1;
	}

	return 0;
}

MODULE = Log::Journald	PACKAGE = Log::Journald		

# A simple print function. Just logs in a single message with a priority. 
int
journal_log(prio, msg)
		int prio;
		const char *msg;
	CODE:
		struct iovec *logv;

		logv = alloc_iovec(2);
		if (logv == NULL) {
			errno = ENOMEM;
			XSRETURN_UNDEF;
		}

		IOVEC_FMT(logv[0], "PRIORITY=%d", prio);
		IOVEC_FMT(logv[1], "MESSAGE=%s", msg);

		if (submit_iovec(logv, items) == 0) {
			RETVAL = 1;
		} else {
			RETVAL = 0;
		}
		free(logv[0].iov_base);
		free(logv[1].iov_base);
		free(logv);
		if (RETVAL == 0)
			XSRETURN_UNDEF;
	OUTPUT:
		RETVAL

# Raw log sending function. Sends its arguments as they are.
int
send(key, value, ...)
	CODE:
		int i;
		struct iovec *logv;

		if (items % 2)
			croak("odd arguments to Log::Journald::send");
		logv = alloc_iovec(items / 2);
		if (logv == NULL) {
			errno = ENOMEM;
			XSRETURN_UNDEF;
		}

		for (i = 0; i < items; i += 2) {
			STRLEN key_len, val_len, len;
			const char *key, *val;
			char *msg;

			key = SvPV(ST(i), key_len);
			val = SvPV(ST(i+1), val_len);
			len = key_len + 1 + val_len;
			logv[i / 2].iov_base = msg = malloc(len);
			if (msg == NULL) {
				logv[i / 2].iov_len = -1;
			} else {
				memcpy(msg, key, key_len);
				msg += key_len;
				*msg++ = '=';
				memcpy(msg, val, val_len);
				logv[i / 2].iov_len = len;
			}
		}

		if (submit_iovec(logv, items / 2) == 0) {
			RETVAL = 1;
		} else {
			RETVAL = 0;
		}
		for (i = 0; i < items; i += 2)
			free (logv[i / 2].iov_base);
		free(logv);
		if (RETVAL == 0)
			XSRETURN_UNDEF;
	OUTPUT:
		RETVAL

# Raw log sending function. Sends its arguments as they are.
int
sendv(arg, ...)
	CODE:
		int i;
		struct iovec *logv;

		logv = alloc_iovec(items);
		if (logv == NULL) {
			errno = ENOMEM;
			XSRETURN_UNDEF;
		}

		for (i = 0; i < items; i++) {
			logv[i].iov_base = SvPV(ST(i), logv[i].iov_len);
		}

		if (submit_iovec(logv, items) == 0) {
			RETVAL = 1;
		} else {
			RETVAL = 0;
		}
		free(logv);
		if (RETVAL == 0)
			XSRETURN_UNDEF;
	OUTPUT:
		RETVAL
