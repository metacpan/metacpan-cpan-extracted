#line 1 "inc/Module/Install/Compiler.pm - /usr/local/lib/perl5/site_perl/5.8.7/Module/Install/Compiler.pm"
package Module::Install::Compiler;
use Module::Install::Base; @ISA = qw(Module::Install::Base);
$VERSION = '0.01';

use strict;
use File::Basename ();

sub c_files {
    my $self = shift;
    require Config;
    my $_o = $Config::Config{_o};
    $self->makemaker_args(OBJECT => join ' ', map { substr($_, 0, -2) . $_o } @_);
}

sub inc_paths {
    my $self = shift;
    $self->makemaker_args(INC => join ' ', map { "-I$_" } @_);
}

sub lib_paths {
    my $self = shift;
    $self->makemaker_args(LIBS => join ' ', map { "-L$_" } @_);
}

sub lib_links {
    my $self = shift;
    $self->makemaker_args(
        LIBS => join ' ', $self->makemaker_args->{LIBS}, map { "-l$_" } @_
    );
}

sub optimize_flags {
    my $self = shift;
    $self->makemaker_args(OPTIMIZE => join ' ', @_);
}

1;
