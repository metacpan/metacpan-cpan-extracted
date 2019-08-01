package Config::AutoConf::Log4cplus;

use strict;
use warnings;

use parent qw(Config::AutoConf);

sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    # XXX might add c++ if required for some operating systems
    return $self;
}

#    AX_CHECK_LIB_FLAGS([log4cplus], [stdc++,stdc++ unwind], [log4cplus_initialize();], [
#    AC_INCLUDES_DEFAULT
##include <log4cplus/clogger.h>
#      ], [log4cplus >= 2.0.0], [

sub check_log4cplus_prerequisites
{
    my $self = shift->_get_instance();

    $self->{config}->{cc} or $self->check_prog_cc();
    $self->check_produce_loadable_xs_build() or die "Can't produce loadable XS module";
}

sub check_liblog4cplus
{
    my $self = shift->_get_instance();
    $self->pkg_config_package_flags("log4cplus");
    my $have_liblog4cplus;

    if ($have_liblog4cplus = $self->search_libs("log4cplus_initialize", ["log4cplus"], [[qw(stdc++)], [qw(stdc++ unwind)]]))
    {
        $self->check_funcs([qw(log4cplus_file_reconfigure log4cplus_str_reconfigure log4cplus_basic_reconfigure)]);
        $self->check_funcs([qw(log4cplus_add_log_level log4cplus_remove_log_level)]);
    }

    return $have_liblog4cplus;
}

sub check_log4cplus_header
{
    my $self = shift->_get_instance();

    $self->check_all_headers(qw(log4cplus/clogger.h));
}

1;
