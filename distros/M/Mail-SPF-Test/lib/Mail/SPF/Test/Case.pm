#
# Mail::SPF::Test::Case
# SPF test-suite test case class.
#
# (C) 2006 Julian Mehnle <julian@mehnle.net>
# $Id: Case.pm 27 2006-12-23 20:11:21Z Julian Mehnle $
#
##############################################################################

package Mail::SPF::Test::Case;

=head1 NAME

Mail::SPF::Test::Case - SPF test-suite test case class

=cut

use warnings;
use strict;

use base 'Mail::SPF::Test::Base';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 SYNOPSIS

    use Mail::SPF::Test::Case;
    
    my $test_case   = Mail::SPF::Test::Case->new_from_yaml_struct($struct);
    
    my $name        = $test_case->name;
    my $description = $test_case->description;
    my $comment     = $test_case->comment;
    my @spec_refs   = $test_case->spec_refs(undef || '*.*/*');
    
    my $scope       = $test_case->scope;
    my $identity    = $test_case->identity;
    
    my $ip_address  = $test_case->ip_address;
    my $helo_identity
                    = $test_case->helo_identity;
    
    my $expected_results
                    = $test_case->expected_results;
    my $expected_explanation
                    = $test_case->expected_explanation;
    
    my $ok =
        $test_case->is_expected_result($result_code) and
        $expected_explanation eq $authority_explanation;

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

An object of class B<Mail::SPF::Test::Case> represents a single test case
within an SPF test-suite scenario.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Test::Case>

Creates a new SPF test-suite test case object from scratch.

=cut

sub new {
    my ($self, %options) = @_;
    $self = $self->SUPER::new(%options);
    $self->{scope} ||= 'mfrom';
    return $self;
}

=item B<new_from_yaml_struct($yaml_struct)>: returns I<Mail::SPF::Test::Case>

Creates a new SPF test-suite test case object from the given YAML-generated
data structure.

=cut

sub new_from_yaml_struct {
    my ($self, $yaml_struct, %options) = @_;
    my $scope = $yaml_struct->{scope} ||
        (defined($yaml_struct->{identity}) || length($yaml_struct->{mailfrom}) ? 'mfrom' : 'helo');
    $self = $self->new(
        %options,
        name                => $yaml_struct->{name},
        description         => $yaml_struct->{description},
        comment             => $yaml_struct->{comment},
        spec_refs           => $self->arrayify($yaml_struct->{spec}),
        
        scope               => $scope,
        identity            => $yaml_struct->{identity},
        
        ip_address          => $yaml_struct->{host},
        helo_identity       => $yaml_struct->{helo},
        
        expected_results    => $self->arrayify($yaml_struct->{result}),
        expected_explanation
                            => $yaml_struct->{explanation}
    );
    if ($self->{scope} eq 'helo') {
        $self->{identity}  ||= $yaml_struct->{helo};
    }
    elsif ($self->{scope} eq 'mfrom') {
        $self->{identity}  ||= $yaml_struct->{mailfrom};
    }
    return $self;
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<name>: returns I<string>

Returns the name of the test case.

=item B<description>: returns I<string>

Returns the description of the test case.

=item B<comment>: returns I<string>

Returns the optional comment of the test case.

=item B<spec_refs>: returns I<list> of I<string>

Returns a list of the specification references for the test case.

=item B<scope>: returns I<string>

Returns the SPF identity's scope for the test case.

=item B<identity>: returns I<string>

Returns the SPF identity for the test case.

=item B<ip_address>: returns I<string>

Returns the SMTP sender's IP address for the test case.

=item B<helo_identity>: returns I<string>

Returns the SPF C<HELO> identity for the test case.

=item B<expected_results>: returns I<list> of I<string>

Returns the list of acceptable SPF result codes for the test case.

=item B<is_expected_result($result_code)>: returns I<boolean>

Returns B<true> if the given result code is among the acceptable SPF result
codes for the test case, B<false> otherwise.

=item B<expected_explanation>: returns I<string>

Returns the expected authority explanation string for the test case.

=cut

# Make read-only accessors:
__PACKAGE__->make_accessor($_, TRUE)
    foreach qw(
        name description comment
        scope identity ip_address helo_identity
        expected_explanation
    );

sub spec_refs {
    my ($self, $granularity) = @_;
    $granularity ||= '*.*/*';
    my @refs = @{$self->{spec_refs}};
    if ($granularity eq '*') {
        @refs = map(/^(\p{IsAlnum}+)/ && $1, @refs);
    }
    elsif ($granularity eq '*.*') {
        @refs = map(/^([^\/]+)/ && $1, @refs);
    }
    return @refs;
}

sub expected_results {
    my ($self) = @_;
    return @{$self->{expected_results}};
}

sub is_expected_result {
    my ($self, $result_code) = @_;
    my %expected_results; @expected_results{$self->expected_results} = ();
    return exists($expected_results{$result_code});
}

=back

=cut

sub arrayify {
    my ($self, $value) = @_;
    return []
        if not defined($value);
    return [$value]
        if not ref($value) eq 'ARRAY';
    return $value;
}

=head1 SEE ALSO

L<Mail::SPF::Test>

For availability, support, and license information, see the README file
included with Mail::SPF::Test.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
