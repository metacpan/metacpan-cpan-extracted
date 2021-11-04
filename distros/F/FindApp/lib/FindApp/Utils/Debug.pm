package FindApp::Utils::Debug;

use v5.10;
use strict;
use warnings;


use Carp         qw(carp croak cluck confess);
use File::Spec   qw();

use FindApp::Vars           qw( :all            );
use FindApp::Utils::Assert  qw( :all            );
use FindApp::Utils::Syntax  qw( function        );
use FindApp::Utils::Foreign qw( abs2rel         );
use FindApp::Utils::Objects qw( class_prune     );

#################################################################

use Exporter qw(import);
our $VERSION   = 1.0;
our @EXPORT_OK = (
    <ENTER_TRACE{,_{1,2,3,4,5}}>, 
    qw(
        debug      
        debugging 
        tracing    
    ), 
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#################################################################

sub debug      ;
sub debugging  ;
sub hail_mary  ;
sub safety_net ;
sub tracing    ;

sub ENTER_TRACE   ;
sub ENTER_TRACE_1 ;
sub ENTER_TRACE_2 ;
sub ENTER_TRACE_3 ;
sub ENTER_TRACE_4 ;
sub ENTER_TRACE_5 ;

#################################################################

sub tracing {
    my $self = shift;
    if (@_) {
        $Tracing = shift;
        safety_net($Debugging || $Tracing);
    }
    return $Tracing;
}

sub debug {
    return unless $Debugging;
    my($pack, $file, $line, $sub) = caller(0);
    $file = abs2rel($file);
    no overloading;
    my $suffix = $Debugging > 1 && " at $file line $line";
    local @SIG{<__{WARN,DIE}__>};
    print STDERR "@_$suffix\n";
}

sub safety_net {
    my($enable) = @_;
    $SIG{__DIE__} = $enable ? \&hail_mary : undef;
}

sub debugging {
    my $self = shift;
    if (@_) { 
        $Debugging = shift;
        safety_net($Debugging || $Tracing);
    }
    return $Debugging;
}

sub hail_mary {
    return if $^S;
    local @SIG{<__{WARN,DIE}__>};
    confess "caught exception: @_";
}

#################################################################

for my $func (<debugging tracing>) { 
    no strict "refs";
    my $var = ucfirst $func;
    $func->($$var) if $$var;
}

for my $LEVEL (1 .. 5) {
    function "ENTER_TRACE_${LEVEL}" => sub {
        return unless $Tracing && $Tracing >= $LEVEL;
        my($pack, $file, $line, $sub) = caller(1);
        $file = abs2rel($file);
        no overloading;
        local @SIG{<__{WARN,DIE}__>};
        my @safe_args = map { defined() ? $_ : "(undef)" } @_;
        print STDERR class_prune "$sub @safe_args\n";
    }
}

*ENTER_TRACE = \&ENTER_TRACE_1;

1;

=encoding utf8

=head1 NAME

FindApp::Utils::Debug - FIXME

=head1 SYNOPSIS

 use FindApp::Utils::Debug;

=head1 DESCRIPTION

=head2 Exports

=over

=item ENTER_TRACE

=item ENTER_TRACE_1

=item ENTER_TRACE_2

=item ENTER_TRACE_3

=item ENTER_TRACE_4

=item ENTER_TRACE_5

=item debug

=item debugging

=item hail_mary

=item safety_net

=item tracing

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

