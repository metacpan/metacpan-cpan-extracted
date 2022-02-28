package Git::Lint::Check::Message;

use strict;
use warnings;

use parent 'Git::Lint::Check';

use Git::Lint::Command;

our $VERSION = '0.009';

sub message {
    my $self = shift;
    my $args = {
        file => undef,
        @_,
    };

    foreach ( keys %{$args} ) {
        die "$_ is a required argument"
            unless defined $args->{$_};
    }

    my $lines_arref = [];
    open( my $message_fh, '<', $args->{file} )
        or die 'open: ' . $args->{file} . ': ' . $!;
    while ( my $line = <$message_fh> ) {
        chomp $line;
        push @{$lines_arref}, $line;
    }
    close($message_fh);

    unless ($lines_arref) {
        exit 0;
    }

    return $lines_arref;
}

sub format_issue {
    my $self = shift;
    my $args = {
        check => undef,
        @_,
    };

    foreach ( keys %{$args} ) {
        die "$_ is a required argument"
            unless defined $args->{$_};
    }

    my $message = $args->{check};

    return { message => $message };
}

sub parse {
    my $self = shift;
    my $args = {
        input => undef,
        match => undef,
        check => undef,
        @_,
    };

    foreach ( keys %{$args} ) {
        die "$_ is a required argument"
            unless defined $args->{$_};
    }

    die 'match argument must be a code ref'
        unless ref $args->{match} eq 'CODE';

    my @issues;
    if ( $args->{match}->( $args->{input} ) ) {
        push @issues, $self->format_issue( check => $args->{check}, );
    }

    return @issues;
}

1;

__END__

=pod

=head1 NAME

Git::Lint::Check::Message - parent module for message check modules

=head1 SYNOPSIS

 use parent 'Git::Lint::Check::Message';

 # inside of the child module, check method
 sub check {
     my $self  = shift;
     my $input = shift;

     my $match = sub {
         my $lines_arref = shift;
         my $summary     = shift @{$lines_arref};
         return 1 if length $summary > SUMMARY_LENGTH;
         return;
     };

     my @issues = $self->parse(
         input => $input,
         match => $match,
         check => $check_message,
     );

     return @issues;
 }

=head1 DESCRIPTION

C<Git::Lint::Check::Message> provides methods for L<Git::Lint> message check modules.

This module is not meant to be initialized directly.

=head1 ADDING CHECK MODULES

To add check functionality to L<Git::Lint>, additional check modules can be created as child modules to C<Git::Lint::Check::Message>.

For an example to start creating message check modules, see L<Git::Lint::Check::Message::SummaryLength> or any message check module released within this distribution.

=head2 CHECK MODULE REQUIREMENTS

Child modules must implement the C<check> method which gathers, formats, and returns a list of issues.

The methods within this module can be used to parse and report the issues in the expected format, but are not required to be used.

The issues returned from message check modules must be a list of hash refs each with a message key and value.

 my @issues = (
     { message => 'summary length (50 characters of less)' }
 );
 
=head1 CONSTRUCTOR

=head2 new

This method is inherited from L<Git::Lint::Check>.

=head1 METHODS

=head2 message

Reads the input commit message from file and returns the contents.

=head3 ARGUMENTS

=over

=item file

=back

=head3 RETURNS

An array ref of the commit message input.

=head2 format_issue

Formats the match information into the expected issue format.

=head3 ARGUMENTS

=over

=item check

The check name or message to format.

=back

=head3 RETURNS

A hash ref with the message key and value.

=head2 parse

Parses the commit message input for violations using the match subref check.

=head3 ARGUMENTS

=over

=item input

Array ref of the message input to check.

=item match

Code ref (sub reference) containing the check logic.

=item check

The check name or message to use for reporting issues.

=back

=head3 RETURNS

A list of hashrefs of formatted issues.

=cut
