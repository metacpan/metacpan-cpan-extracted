use 5.013;
# Need at least perl 5.13; older versions don't provide some xs macro used here.
# However, fanotify was released in 2011; perl 5.13 was released in 2010. We
# probably will not loose any users when relying on a newer perl.

use ExtUtils::MakeMaker;
use ExtUtils::Liblist;
use ExtUtils::Constant 0.23 'WriteConstants';

#
# Do not try to build on systems /known/ not to work
#
if ($^O ne 'linux') {
	print("OS $^O unsupported (fanotify is Linux only)\n");
	exit(0);
}

WriteMakefile(
    NAME                => 'Linux::Fanotify',
    AUTHOR              => 'Bastian Friedrich <bastian.friedrich@collax.com>',
    VERSION_FROM        => 'lib/Linux/Fanotify.pm',
    ABSTRACT_FROM       => 'lib/Linux/Fanotify.pm',
    PREREQ_PM           => {
        'Exporter'      => 0,
        'Test::More'    => 0,
        'Test::Builder' => 0,
    },

    NEEDS_LINKING       => 1,
    INC                 => '-I.',

    # TYPEMAPS		=> [qw(typemap)],

    EXE_FILES           => [],
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Linux-Fanotify-*.tar.* const-c.inc const-xs.inc' },
);

my @consts = qw(
	FAN_ACCESS
	FAN_MODIFY
	FAN_CLOSE_WRITE
	FAN_CLOSE_NOWRITE
	FAN_OPEN
	FAN_Q_OVERFLOW
	FAN_OPEN_PERM
	FAN_ACCESS_PERM
	FAN_ONDIR
	FAN_EVENT_ON_CHILD
	FAN_CLOSE
	FAN_CLOEXEC
	FAN_NONBLOCK
	FAN_CLASS_NOTIF
	FAN_CLASS_CONTENT
	FAN_CLASS_PRE_CONTENT
	FAN_ALL_CLASS_BITS
	FAN_UNLIMITED_QUEUE
	FAN_UNLIMITED_MARKS
	FAN_ALL_INIT_FLAGS
	FAN_MARK_ADD
	FAN_MARK_REMOVE
	FAN_MARK_DONT_FOLLOW
	FAN_MARK_ONLYDIR
	FAN_MARK_MOUNT
	FAN_MARK_IGNORED_MASK
	FAN_MARK_IGNORED_SURV_MODIFY
	FAN_MARK_FLUSH
	FAN_ALL_MARK_FLAGS
	FAN_ALL_EVENTS
	FAN_ALL_PERM_EVENTS
	FAN_ALL_OUTGOING_EVENTS
	FANOTIFY_METADATA_VERSION
	FAN_ALLOW
	FAN_DENY
	FAN_NOFD
);

WriteConstants(
	PROXYSUBS => {autoload => 1},
	NAME => 'Linux::Fanotify',
	NAMES => \@consts,
);
