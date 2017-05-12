#
# Mail::SPF::Test
# SPF test-suite class.
#
# (C) 2006-2007 Julian Mehnle <julian@mehnle.net>
# $Id: Test.pm 105 2007-05-30 20:41:57Z Julian Mehnle $
#
##############################################################################

package Mail::SPF::Test;

=head1 NAME

Mail::SPF::Test - SPF test-suite class

=head1 VERSION

1.001

=cut

use version; our $VERSION = qv('1.001');

use warnings;
use strict;

use base 'Mail::SPF::Test::Base';

use Mail::SPF::Test::Scenario;

use IO::File;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 SYNOPSIS

    use Mail::SPF::Test;
    
    my $test_suite = Mail::SPF::Test->new_from_yaml_file('rfc4408-tests.yml');
    
    foreach my $scenario ($test_suite->scenarios) {
        printf("Scenario '%s'\n", $scenario->description);
        
        foreach my $test_case ($scenario->test_cases) {
            my $name        = $test_case->name;
            my $description = $test_case->description;
            my $comment     = $test_case->comment;
            my @spec_refs   = $test_case->spec_refs(undef || '*.*/*');
            
            my $scope       = $test_case->scope;
            my $identity    = $test_case->identity;
            
            my $ip_address  = $test_case->ip_address;
            my $helo_identity
                            = $test_case->helo_identity;
            
            my @expected_results
                            = $test_case->expected_results;
            my $expected_explanation
                            = $test_case->expected_explanation;
            
            my $ok =
                $test_case->is_expected_result($result_code) and
                $expected_explanation eq $authority_explanation;
        }
    }

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

B<Mail::SPF::Test> is a class for reading and manipulating SPF test-suite
data.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Test>

Creates a new SPF test-suite object from scratch.

=cut

#sub new {
#    my ($self, %options) = @_;
#    return $self->SUPER::new(%options);
#}

=item B<new_from_yaml($yaml_text, %options)>: returns I<Mail::SPF::Test>

Creates a new SPF test-suite object from the given YAML string.

=cut

sub new_from_yaml {
    my ($self, $yaml_text, %options) = @_;
    $self = $self->new(%options);
    require YAML::Loader;
    my $yaml_loader = YAML::Loader->new();
    my @yaml_scenario_structs = $yaml_loader->load($yaml_text);
    $self->{scenarios} = [
        map(Mail::SPF::Test::Scenario->new_from_yaml_struct($_), @yaml_scenario_structs)
    ];
    return $self;
}

=item B<new_from_yaml_file($file_name, %options)>: returns I<Mail::SPF::Test>

Creates a new SPF test-suite object by reading from the YAML file of the given
name.

=cut

sub new_from_yaml_file {
    my ($self, $file_name, %options) = @_;
    my $file = IO::File->new($file_name, '<');
    defined($file)
        or return undef;
    my $yaml_text = do { local $/; <$file> };
    return $self->new_from_yaml($yaml_text);
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<as_yaml>: returns I<string>

Returns the test-suite object's list of scenarios formatted as a stream of YAML
documents.

=cut

sub as_yaml {
    my ($self) = @_;
    require YAML::Dumper;
    my $yaml_dumper = YAML::Dumper->new();
    my @yaml_scenario_structs = map( $_->as_yaml_struct(), @{$self->{scenarios}} );
    return $yaml_dumper(@yaml_scenario_structs);
}

=item B<scenarios>: returns I<list> of I<Mail::SPF::Test::Scenario>

Returns a list of the test-suite object's scenario objects.

=cut

sub scenarios {
    my ($self) = @_;
    return @{$self->{scenarios}};
}

=back

=head1 SEE ALSO

For availability, support, and license information, see the README file
included with Mail::SPF::Test.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
