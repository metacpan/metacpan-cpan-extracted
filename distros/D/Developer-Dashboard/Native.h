#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#  include <windows.h>
typedef HMODULE dd_library_handle;
static dd_library_handle dd_crypto_handle = NULL;
static DWORD dd_windows_error = ERROR_SUCCESS;
#else
#  include <dlfcn.h>
typedef void *dd_library_handle;
static dd_library_handle dd_crypto_handle = NULL;
#endif

#if defined(__linux__)
#  include <fcntl.h>
#  include <sys/inotify.h>
#  include <unistd.h>
#endif

typedef const void *(*dd_evp_sha256_fn)(void);
typedef int (*dd_pkcs5_pbkdf2_hmac_fn)(const char *, int,
    const unsigned char *, int, int, const void *, int, unsigned char *);

static dd_evp_sha256_fn dd_evp_sha256 = NULL;
static dd_pkcs5_pbkdf2_hmac_fn dd_pkcs5_pbkdf2_hmac = NULL;

/*
 * Load the platform OpenSSL library lazily and resolve only the two stable
 * OpenSSL APIs required by PBKDF2. The handle is intentionally kept open for
 * the interpreter lifetime so cached function pointers remain valid.
 */
static int
dd_load_crypto(void)
{
    if (dd_evp_sha256 && dd_pkcs5_pbkdf2_hmac) {
        return 1;
    }

#ifdef _WIN32
    {
        static const char *names[] = {
            "libcrypto-3-x64.dll", "libcrypto-3.dll",
            "libcrypto-1_1-x64.dll", "libcrypto-1_1.dll", NULL
        };
        int index;
        for (index = 0; names[index]; index++) {
            dd_crypto_handle = LoadLibraryExA(
                names[index], NULL, LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
            if (dd_crypto_handle) {
                break;
            }
        }
        if (!dd_crypto_handle) {
            return 0;
        }
        dd_evp_sha256 = (dd_evp_sha256_fn)GetProcAddress(dd_crypto_handle, "EVP_sha256");
        dd_pkcs5_pbkdf2_hmac = (dd_pkcs5_pbkdf2_hmac_fn)GetProcAddress(dd_crypto_handle, "PKCS5_PBKDF2_HMAC");
    }
#else
    {
        static const char *names[] = {
#  ifdef __APPLE__
            "libcrypto.3.dylib", "libcrypto.dylib",
#  else
            "libcrypto.so.3", "libcrypto.so.1.1", "libcrypto.so",
#  endif
            NULL
        };
        const char *prefix = getenv("OPENSSL_PREFIX");
        int index;

        if (prefix && *prefix) {
            char path[PATH_MAX];
#  ifdef __APPLE__
            snprintf(path, sizeof(path), "%s/lib/libcrypto.dylib", prefix);
#  else
            snprintf(path, sizeof(path), "%s/lib/libcrypto.so", prefix);
#  endif
            dd_crypto_handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
        }
        for (index = 0; !dd_crypto_handle && names[index]; index++) {
            dd_crypto_handle = dlopen(names[index], RTLD_NOW | RTLD_LOCAL);
        }
        if (!dd_crypto_handle) {
            return 0;
        }
        dd_evp_sha256 = (dd_evp_sha256_fn)dlsym(dd_crypto_handle, "EVP_sha256");
        dd_pkcs5_pbkdf2_hmac = (dd_pkcs5_pbkdf2_hmac_fn)dlsym(dd_crypto_handle, "PKCS5_PBKDF2_HMAC");
    }
#endif

    if (!dd_evp_sha256 || !dd_pkcs5_pbkdf2_hmac) {
#ifdef _WIN32
        FreeLibrary(dd_crypto_handle);
        dd_crypto_handle = NULL;
#else
        dlclose(dd_crypto_handle);
        dd_crypto_handle = NULL;
#endif
        dd_evp_sha256 = NULL;
        dd_pkcs5_pbkdf2_hmac = NULL;
        return 0;
    }
    return 1;
}
