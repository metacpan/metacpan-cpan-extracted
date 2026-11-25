MODULE = Developer::Dashboard    PACKAGE = Developer::Dashboard::Crypto::PBKDF2

# _xs_native_available()
# Reports whether a compatible OpenSSL PBKDF2 implementation can be loaded.
# Input: none.
# Output: true when the OpenSSL entry points are available; otherwise false.
int
_xs_native_available()
  CODE:
    RETVAL = dd_load_crypto() ? 1 : 0;
  OUTPUT:
    RETVAL

# _xs_pbkdf2_sha256(password, salt, iterations)
# Derives a 32-byte PBKDF2-HMAC-SHA256 key using the platform OpenSSL library.
# Input: byte strings and an iteration count representable by the OpenSSL API.
# Output: lowercase hexadecimal key, or undef when OpenSSL is not available.
SV *
_xs_pbkdf2_sha256(password, salt, iterations)
    SV *password
    SV *salt
    IV iterations
  PREINIT:
    STRLEN password_length;
    STRLEN salt_length;
    const char *password_bytes;
    const unsigned char *salt_bytes;
    unsigned char output[32];
    char hex[65];
    static const char digits[] = "0123456789abcdef";
    int index;
    int ok;
  CODE:
    if (!SvOK(password) || SvROK(password) || !SvOK(salt) || SvROK(salt)) {
        croak("PBKDF2 password and salt must be defined scalars");
    }
    if (iterations < 1 || iterations > INT_MAX) {
        croak("PBKDF2 iterations are outside the supported range");
    }
    password_bytes = SvPVbyte(password, password_length);
    salt_bytes = (const unsigned char *)SvPVbyte(salt, salt_length);
    if (password_length > INT_MAX || salt_length > INT_MAX) {
        croak("PBKDF2 password or salt is too large");
    }
    if (!dd_load_crypto()) {
        RETVAL = newSV(0);
        XSRETURN_UNDEF;
    }
    ok = dd_pkcs5_pbkdf2_hmac(password_bytes, (int)password_length,
        salt_bytes, (int)salt_length, (int)iterations,
        dd_evp_sha256(), (int)sizeof(output), output);
    if (ok != 1) {
        croak("OpenSSL PKCS5_PBKDF2_HMAC failed");
    }
    for (index = 0; index < (int)sizeof(output); index++) {
        hex[index * 2] = digits[output[index] >> 4];
        hex[index * 2 + 1] = digits[output[index] & 0x0f];
    }
    hex[64] = '\0';
    RETVAL = newSVpvn(hex, 64);
  OUTPUT:
    RETVAL

MODULE = Developer::Dashboard    PACKAGE = Developer::Dashboard::IndicatorStore::Watch

# _xs_inotify_init()
# Creates a nonblocking, close-on-exec Linux inotify descriptor.
# Input: none.
# Output: file descriptor, or -1 with errno set on failure/non-Linux systems.
int
_xs_inotify_init()
  CODE:
#if defined(__linux__)
    errno = 0;
    RETVAL = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
#else
    errno = ENOSYS;
    RETVAL = -1;
#endif
    SETERRNO(errno, 0);
  OUTPUT:
    RETVAL

# _xs_inotify_add_watch(descriptor, path, mask)
# Adds a Linux inotify watch to a byte-representable path.
# Input: inotify descriptor, path bytes, and event mask.
# Output: watch descriptor or -1 with errno set on failure/non-Linux systems.
int
_xs_inotify_add_watch(descriptor, path, mask)
    int descriptor
    SV *path
    UV mask
  PREINIT:
    STRLEN path_length;
    const char *path_bytes;
  CODE:
#if defined(__linux__)
    if (!SvOK(path) || SvROK(path)) {
        croak("inotify path must be a defined scalar");
    }
    path_bytes = SvPVbyte(path, path_length);
    if (memchr(path_bytes, '\0', path_length)) {
        croak("inotify path must not contain a null byte");
    }
    errno = 0;
    RETVAL = inotify_add_watch(descriptor, path_bytes, (uint32_t)mask);
#else
    errno = ENOSYS;
    RETVAL = -1;
#endif
    SETERRNO(errno, 0);
  OUTPUT:
    RETVAL

# _xs_win32_find_first_change(path)
# Starts a wide-character Windows directory-change notification.
# Input: a Perl path string encoded as UTF-8.
# Output: native handle as UV, or undef and a saved Win32 error on failure.
SV *
_xs_win32_find_first_change(path)
    SV *path
  PREINIT:
#ifdef _WIN32
    STRLEN path_length;
    const char *path_bytes;
    int wide_length;
    WCHAR *wide_path;
    HANDLE handle;
#endif
  CODE:
#ifdef _WIN32
    if (!SvOK(path) || SvROK(path)) {
        croak("Windows notification path must be a defined scalar");
    }
    path_bytes = SvPVutf8(path, path_length);
    if (path_length > INT_MAX) {
        croak("Windows notification path is too large");
    }
    wide_length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        path_bytes, (int)path_length, NULL, 0);
    if (!wide_length) {
        dd_windows_error = GetLastError();
        RETVAL = newSV(0);
        XSRETURN_UNDEF;
    }
    Newx(wide_path, wide_length + 1, WCHAR);
    if (!MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        path_bytes, (int)path_length, wide_path, wide_length)) {
        dd_windows_error = GetLastError();
        Safefree(wide_path);
        RETVAL = newSV(0);
        XSRETURN_UNDEF;
    }
    wide_path[wide_length] = L'\0';
    handle = FindFirstChangeNotificationW(wide_path, FALSE,
        FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME |
        FILE_NOTIFY_CHANGE_ATTRIBUTES | FILE_NOTIFY_CHANGE_SIZE |
        FILE_NOTIFY_CHANGE_LAST_WRITE);
    dd_windows_error = handle == INVALID_HANDLE_VALUE ? GetLastError() : ERROR_SUCCESS;
    Safefree(wide_path);
    if (handle == INVALID_HANDLE_VALUE || handle == NULL) {
        RETVAL = newSV(0);
        XSRETURN_UNDEF;
    }
    RETVAL = newSVuv(PTR2UV(handle));
#else
    RETVAL = newSV(0);
#endif
  OUTPUT:
    RETVAL

# _xs_win32_wait(handle)
# Polls a Windows directory-change notification without blocking.
# Input: native handle represented as UV.
# Output: WaitForSingleObject status; saves GetLastError after WAIT_FAILED.
UV
_xs_win32_wait(handle)
    UV handle
  CODE:
#ifdef _WIN32
    RETVAL = (UV)WaitForSingleObject(INT2PTR(HANDLE, handle), 0);
    dd_windows_error = RETVAL == WAIT_FAILED ? GetLastError() : ERROR_SUCCESS;
#else
    RETVAL = (UV)-1;
#endif
  OUTPUT:
    RETVAL

# _xs_win32_next_change(handle)
# Rearms a Windows change notification after an event.
# Input: native handle represented as UV.
# Output: nonzero on success; saves GetLastError on failure.
int
_xs_win32_next_change(handle)
    UV handle
  CODE:
#ifdef _WIN32
    RETVAL = FindNextChangeNotification(INT2PTR(HANDLE, handle)) ? 1 : 0;
    dd_windows_error = RETVAL ? ERROR_SUCCESS : GetLastError();
#else
    RETVAL = 0;
#endif
  OUTPUT:
    RETVAL

# _xs_win32_close_change(handle)
# Closes one Windows directory-change notification handle.
# Input: native handle represented as UV.
# Output: nonzero on success; saves GetLastError on failure.
int
_xs_win32_close_change(handle)
    UV handle
  CODE:
#ifdef _WIN32
    RETVAL = FindCloseChangeNotification(INT2PTR(HANDLE, handle)) ? 1 : 0;
    dd_windows_error = RETVAL ? ERROR_SUCCESS : GetLastError();
#else
    RETVAL = 0;
#endif
  OUTPUT:
    RETVAL

# _xs_win32_last_error()
# Returns the most recent error captured by a Windows notification operation.
# Input: none.
# Output: Win32 error code, or zero on non-Windows systems.
UV
_xs_win32_last_error()
  CODE:
#ifdef _WIN32
    RETVAL = (UV)dd_windows_error;
#else
    RETVAL = 0;
#endif
  OUTPUT:
    RETVAL
