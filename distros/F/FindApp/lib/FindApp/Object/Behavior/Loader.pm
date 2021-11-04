package FindApp::Object::Behavior::Loader;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Utils qw(:all);

my %Internal = map { $_ => 1 } @CARP_NOT;

sub foreign_caller {
    my $frame = 0;
    my($pkg, $file, $line, $sub);
    while (1) { 
        ($pkg, $file, $line, $sub) = caller($frame);
        last unless $pkg;
        last if $sub eq "FindApp::Exporter::import";
        last unless $pkg =~ /^FindApp\b/;
        last unless $Internal{$pkg};
        $frame++;
        panic("runaway frame search") if $frame > 100;
    }
    croak "can't find importing package" unless $pkg;
    return $pkg;
}

use namespace::clean;

use pluskeys qw{
    MODULES_USED
    FILES_REQUIRED
};

sub init { &ENTER_TRACE;
    my($self) = @_;
    $self->maybe::next::method;
    $$self{+MODULES_USED}   = [];
    $$self{+FILES_REQUIRED} = [];
}

# overrides the f:o:Behavior method, not the f:o:s:Group Method.
sub export_lib_to_env { &ENTER_TRACE;
    my $self = &myself;
    $self->next::method(@_); # first get @INC setup
    $self->load_wanted;      # so we can load whatever they asked for
}

sub load_wanted { &ENTER_TRACE;
    my $self = &myself;
    return unless my @wanted = map { $self->$_->wanted } <rootdir libdirs>;
    $self->load_libraries(@wanted);
}

sub load_libraries { &ENTER_TRACE;
    my $self = &myself;
    return unless @_;
    $self->load_modules(grep /^\w+(?:::\w+)+$/ => @_);
    $self->load_files  (grep /\.p[lm]$/        => @_);
}

sub load_modules { &ENTER_TRACE; 
    my($self, $caller) = (&myself, &foreign_caller);
    for my $mod (@_) {
        debug "load $mod into $caller";
        eval qq{package $caller; use $mod; 1} || die;
        $self->another_module_used($mod);
    }
}

sub another_module_used { 
    my $self = &myself;
    push @{ $$self{+MODULES_USED} }, @_;
}

sub used_modules {
    my $self = &myself;
    @{ $$self{+MODULES_USED} };
}

sub load_files { &ENTER_TRACE;
    my $self = &myself;
    for my $file (@_) { 
        require "$file";  # the "new" version stuff has messed this all up!
        $self->another_file_required($file);
    }
}

sub another_file_required {
    my $self = &myself;
    push @{ $$self{+FILES_REQUIRED} }, @_;
}

sub required_files {
    my $self = &myself;
    @{ $$self{+FILES_REQUIRED} };
}

1;

=encoding utf8

=head1 NAME

FindApp::Loader - FIXME

=head1 SYNOPSIS

 use FindApp::Loader;

=head1 DESCRIPTION

=head2 Pluskey Attributes

These are all private; use the methods instead.

=over

=item MODULES_USED

Reference to array of modules actually used.

=item FILES_REQUIRED

Reference to array of files actually required.

=back

=head2 Methods

=over

=item another_file_required

=item another_module_used

=item export_lib_to_env

=item load_files

=item load_libraries

=item load_modules

=item load_wanted

=item required_files

=item used_modules

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

