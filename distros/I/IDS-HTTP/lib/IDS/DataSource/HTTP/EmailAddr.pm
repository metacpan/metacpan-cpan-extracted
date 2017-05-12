# HTTP Email Address (for things like From)
# Should probably be a Mail:: not IDS::DataSource::HTTP:: object
#
# subclass of HTTP; see that for interface requirements
#

package IDS::DataSource::HTTP::EmailAddr;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

use IDS::DataSource::HTTP::Host;

$IDS::DataSource::HTTP::EmailAddr::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"}, $self->{"host"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my @tokens;
    my $token;

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$data'");
    
    # Contrary to the standard, google and microsoft both use (at)
    # instead of @ in the From: line.  Sigh.
    if ($data =~ /^([^@]+)(@|\(at\))([^@]+)$/) {
	my $user = $1;
	my $host = $3;

	$token = "Email user: ";
	$token .= ${$self->{"params"}}{"email_user_length_only"}
	    ? length($user)
	    : $user;
	push @tokens, $token;

	$self->{"host"} = new IDS::DataSource::HTTP::Host($self->{"params"}, $host);
	push @tokens, $self->{"host"}->tokens;
    } else {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
                 ${$self->{"params"}}{"source"} .
                 " invalid email addr in '$data'\n";
        $self->warn($pmsg, \@tokens, "!Invalid email addr");
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
}

# accessor functions not provided by the superclass

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Algorithm>, L<IDS::DataSource>

=cut

1;
