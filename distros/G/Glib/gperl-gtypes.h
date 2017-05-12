#ifndef __GPERL_GTYPES_H__
#define __GPERL_GTYPES_H__ 1

#include <glib-object.h>

G_BEGIN_DECLS

/* --- Enums/Flags: --------------------------------------------------------- */

#define GPERL_TYPE_CONNECT_FLAGS gperl_connect_flags_get_type ()
GType gperl_connect_flags_get_type (void) G_GNUC_CONST;

#if GLIB_CHECK_VERSION (2, 6, 0)
#define GPERL_TYPE_KEY_FILE_FLAGS gperl_key_file_flags_get_type()
GType gperl_key_file_flags_get_type (void) G_GNUC_CONST;
#endif

#define GPERL_TYPE_LOG_LEVEL_FLAGS gperl_log_level_flags_get_type ()
GType gperl_log_level_flags_get_type (void) G_GNUC_CONST;

#if GLIB_CHECK_VERSION (2, 6, 0)
#define GPERL_TYPE_OPTION_FLAGS gperl_option_flags_get_type ()
GType gperl_option_flags_get_type (void) G_GNUC_CONST;
#endif

#if GLIB_CHECK_VERSION (2, 12, 0)
#define GPERL_TYPE_OPTION_ARG gperl_option_arg_get_type ()
GType gperl_option_arg_get_type (void) G_GNUC_CONST;
#endif

/* the obvious G_TYPE_PARAM_FLAGS is taken by GParamSpecFlags. */
#define GPERL_TYPE_PARAM_FLAGS gperl_param_flags_get_type ()
GType gperl_param_flags_get_type (void) G_GNUC_CONST;

#define GPERL_TYPE_SIGNAL_FLAGS gperl_signal_flags_get_type ()
GType gperl_signal_flags_get_type (void) G_GNUC_CONST;

#define GPERL_TYPE_SPAWN_FLAGS gperl_spawn_flags_get_type ()
GType gperl_spawn_flags_get_type (void) G_GNUC_CONST;

#if GLIB_CHECK_VERSION (2, 14, 0)
#define GPERL_TYPE_USER_DIRECTORY gperl_user_directory_get_type ()
GType gperl_user_directory_get_type (void) G_GNUC_CONST;
#endif

/* --- Error values: -------------------------------------------------------- */

#if GLIB_CHECK_VERSION (2, 12, 0)
#define GPERL_TYPE_BOOKMARK_FILE_ERROR gperl_bookmark_file_error_get_type ()
GType gperl_bookmark_file_error_get_type (void) G_GNUC_CONST;
#endif /* GLIB_CHECK_VERSION (2, 12, 0) */

#define GPERL_TYPE_CONVERT_ERROR gperl_convert_error_get_type ()
GType gperl_convert_error_get_type (void) G_GNUC_CONST;

#define GPERL_TYPE_FILE_ERROR gperl_file_error_get_type ()
GType gperl_file_error_get_type (void) G_GNUC_CONST;

#if GLIB_CHECK_VERSION (2, 6, 0)
#define GPERL_TYPE_KEY_FILE_ERROR gperl_key_file_error_get_type ()
GType gperl_key_file_error_get_type (void) G_GNUC_CONST;
#endif /* GLIB_CHECK_VERSION (2, 6, 0) */

#define GPERL_TYPE_IO_ERROR gperl_io_error_get_type ()
GType gperl_io_error_get_type (void) G_GNUC_CONST;

#define GPERL_TYPE_IO_CHANNEL_ERROR gperl_io_channel_error_get_type ()
GType gperl_io_channel_error_get_type (void) G_GNUC_CONST;

#define GPERL_TYPE_MARKUP_ERROR gperl_markup_error_get_type ()
GType gperl_markup_error_get_type (void) G_GNUC_CONST;

#define GPERL_TYPE_SHELL_ERROR gperl_shell_error_get_type ()
GType gperl_shell_error_get_type (void) G_GNUC_CONST;

#define GPERL_TYPE_SPAWN_ERROR gperl_spawn_error_get_type ()
GType gperl_spawn_error_get_type (void) G_GNUC_CONST;

#define GPERL_TYPE_THREAD_ERROR gperl_thread_error_get_type ()
GType gperl_thread_error_get_type (void) G_GNUC_CONST;

#if GLIB_CHECK_VERSION (2, 24, 0)
#define GPERL_TYPE_VARIANT_PARSE_ERROR gperl_variant_parse_error_get_type ()
GType gperl_variant_parse_error_get_type (void);
#endif

G_END_DECLS

#endif /* __GPERL_GTYPES_H__ */
