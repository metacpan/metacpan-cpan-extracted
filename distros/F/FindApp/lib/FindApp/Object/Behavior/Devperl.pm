package FindApp::Object::Behavior::Devperl;

use v5.10;
use strict;
use warnings;
use mro "c3";

use Config         qw( %Config );
use FindApp::Vars  qw( :all    );
use FindApp::Utils qw( :all    );

{ my $iota; BEGIN { $iota = 0 } use constant {
    DEVPERL__MIN => $iota - 0,  # need expr so compiler doesn't over-optimize
    DEVPERL_NONE => $iota ++ ,
    DEVPERL_SOME => $iota ++ ,
    DEVPERL_ALL  => $iota ++ ,
    DEVPERL__MAX => $iota - 1,
  };
}

use namespace::clean;

################################################################

# Declare attributes.  These can normally be cleaned, 
# including here, but since we haven't cleaned the others,
# might was well leave it.
use pluskeys qw(
    WHICH_DEVPERLS
);

sub init { &ENTER_TRACE;
    my($self) = @_;
    $self->maybe::next::method;
    $self->use_some_devperls;
}

sub copy { &ENTER_TRACE;
    my($to, $from) = @_;
    $to->next::method($from);
    $to->forgotten_devperls($from->forgotten_devperls) 
                         if $from->can("forgotten_devperls");
    return $to;
}

sub findapp_root_from_path { &ENTER_TRACE;
    my $self  = &myself;
    my($path) = @_;
    good_args($path);
    my $root = $self->next::method($path) || return;
    for my $dir ($self->subgroup_names) {
        if (my @extra = $self->some_devperl_dir($dir)) {
            $self->group($dir)->found->add(@extra);
        }    
    }    
    return $root;
}

################################################################

sub use_my_devperl {  &ENTER_TRACE;
    my $self = &myself;
    bad_args(@_ > 1);
SWITCH: 
    for (@_ ? @_ : "some") {
        /^ no (ne)? $/x  &&  case { $self->use_no_devperls   };
        /^ some     $/x  &&  case { $self->use_some_devperls };
        /^ all      $/x  &&  case { $self->use_all_devperls  };
        panic "unknown devperl argument: $_";
    }
}

sub use_no_devperls {  &ENTER_TRACE;
    my $self = &myself;
    bad_args(@_ > 0);
    $self->forgotten_devperls(DEVPERL_NONE);
}

sub use_some_devperls {  &ENTER_TRACE;
    my $self = &myself;
    bad_args(@_ > 0);
    $self->forgotten_devperls(DEVPERL_SOME);
}

sub use_all_devperls {  &ENTER_TRACE;
    my $self = &myself;
    bad_args(@_ > 0);
    $self->forgotten_devperls(DEVPERL_ALL);
}

sub forgotten_devperls {  &ENTER_TRACE_2;
    my $self = &myself;
    bad_args(@_ > 1);
    if (@_) {
        my($level) = @_;
        good_args looks_like_number $level;
        good_args $level >= DEVPERL__MIN;
        good_args $level <= DEVPERL__MAX;
        $$self{+WHICH_DEVPERLS} = $level;
    }
    return $$self{+WHICH_DEVPERLS};
}

sub some_devperl_dir {  &ENTER_TRACE;
    my $self = &myself;
    my($dir, @args) = @_;
    my $forgotten = $self->forgotten_devperls || return;
    my $method    = $forgotten == DEVPERL_SOME ? "forgotten" : "find";
       $method   .= "_devperl_" . $dir;
    return $self->$method;
}

sub find_devperl_lib {  &ENTER_TRACE_2;
    my $self = &myself;
    return ();   # because we by definition already have it
}

sub forgotten_devperl_lib {  &ENTER_TRACE_3;
    my $self = &myself;
    return $self->find_devperl_lib;
}

sub find_devperl_bin {  &ENTER_TRACE_2;
    my $self = &myself;
    my @devperl_bins = uniq_files @Config{ <{site,vendor,install}bin> };
    return @devperl_bins;
}

sub forgotten_devperl_bin {  &ENTER_TRACE_3;
    my $self = &myself;
    my @bins = $self->find_devperl_bin;
    firsts_not_in_second(@bins, @PATH);
}

sub find_devperl_man {  &ENTER_TRACE_2;
    my $self = &myself;  ## NOT USED
    uniq_files map {dirname} @Config{sysman => <{site,vendor,install}man{1,3}dir>};
}

sub forgotten_devperl_man {  &ENTER_TRACE_3;
    my $self = &myself;
    my @men = $self->find_devperl_man;
    firsts_not_in_second(@men, @MANPATH);
}

1;

=encoding utf8

=head1 NAME

FindApp::Devperl - FIXME

=head1 SYNOPSIS

 use FindApp::Devperl;

=head1 DESCRIPTION

=head2 Pluskey Attributes

These are always private; use the methods insteads.

=over

=item WHICH_DEVPERLS

=back

=head2 Methods

=over

=item copy

=item find_devperl_bin

=item find_devperl_lib

=item find_devperl_man

=item findapp_root

This is an override.

=item findapp_root_from_path

This is an override.

=item forgotten_devperl_bin

=item forgotten_devperl_lib

=item forgotten_devperl_man

=item forgotten_devperls

=item init

=item some_devperl_dir

=item use_all_devperls

=item use_my_devperl

=item use_no_devperls

=item use_some_devperls

=back

=head2 Exports

=over

=item FIXME

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

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

