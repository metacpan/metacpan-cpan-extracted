#
# Mail::SPF::Test::Scenario
# SPF test-suite scenario class.
#
# (C) 2006 Julian Mehnle <julian@mehnle.net>
# $Id: Scenario.pm 27 2006-12-23 20:11:21Z Julian Mehnle $
#
##############################################################################

package Mail::SPF::Test::Scenario;

=head1 NAME

Mail::SPF::Test::Scenario - SPF test-suite scenario class

=cut

use warnings;
use strict;

use base 'Mail::SPF::Test::Base';

use Mail::SPF::Test::Case;

use NetAddr::IP;
use Net::DNS::RR;

#use XML::LibXML;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 SYNOPSIS

    use Mail::SPF::Test::Scenario;
    
    my $scenario = Mail::SPF::Test::Scenario->new_from_yaml_struct($struct);
    
    my $yaml        = $scenario->as_yaml;
    
    my $description = $scenario->description;
    my @test_cases  = $scenario->test_cases;
    my @spec_refs   = $scenario->spec_refs(undef || '*.*/*');
    my @records     = $scenario->records;
    my @records_for_domain
                    = $scenario->records_for_domain($domain, $rr_type);

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

An object of class B<Mail::SPF::Test::Scenario> represents an SPF test-suite
scenario.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Test::Scenario>

Creates a new SPF test-suite scenario object from scratch.

=cut

#sub new {
#    my ($self, %options) = @_;
#    return $self->SUPER::new(%options);
#}

=item B<new_from_yaml_struct($yaml_struct, %options)>: returns I<Mail::SPF::Test::Scenario>

Creates a new SPF test-suite scenario object from the given YAML-generated data
structure.

=cut

sub new_from_yaml_struct {
    my ($self, $yaml_struct, %options) = @_;
    $self = $self->new(%options);
    
    $self->{description}        = $yaml_struct->{description};
    
    my $tests                   = $yaml_struct->{tests};
    my $test_cases              = $self->{test_cases} = {};
    foreach my $test_name (keys(%$tests)) {
        $tests->{$test_name}->{name} = $test_name;
        $test_cases->{$test_name} = Mail::SPF::Test::Case->new_from_yaml_struct($tests->{$test_name});
    }
    
    my $zonedata                = $yaml_struct->{zonedata} || {};
    my $records                 = $self->{records}  = [];
    my $records_by_domain       = $self->{records_by_domain} = {};
    
    DOMAIN:
    foreach my $domain (keys(%$zonedata)) {
        my $records_by_type     = $records_by_domain->{lc($domain)} = {};
        my $txt_rr_synthesis    = TRUE;
        
        RECORD:
        foreach my $record_struct (@{$zonedata->{$domain}}) {
            if (ref($record_struct) eq 'HASH') {
                # TYPE => DATA
                my ($type, $data_struct) = %$record_struct;
                
                if ($data_struct =~ /^(TIMEOUT|RCODE[1-5])$/) {
                    $records_by_type->{$type} = $data_struct;
                }
                elsif ($data_struct eq 'NO-SYNTHESIS' and $type eq 'TXT') {
                    $txt_rr_synthesis = FALSE;
                }
                else {
                    my %data;
                    if ($type eq 'SPF' or $type eq 'TXT') {
                        if ($data_struct eq 'NONE') {
                            $txt_rr_synthesis = FALSE;
                            next RECORD;
                        }
                        else {
                            $data_struct = [$data_struct]
                                if not ref($data_struct);
                            %data = ( char_str_list => $data_struct );
                        }
                    }
                    elsif ($type eq 'A' or $type eq 'AAAA') {
                        my $address = NetAddr::IP->new($data_struct);
                        %data = ( address => $address->addr );  # Normalize IP address.
                    }
                    elsif ($type eq 'MX') {
                        %data = (
                            preference  => $data_struct->[0],
                            exchange    => $data_struct->[1]
                        );
                    }
                    elsif ($type eq 'PTR') {
                        %data = ( ptrdname => $data_struct );
                    }
                    elsif ($type eq 'CNAME') {
                        %data = ( cname => $data_struct );
                    }
                    else {
                        # Unexpected RR type!
                        die("Unexpected RR type '$type' in zonedata");
                    }
                    
                    my $record = Net::DNS::RR->new(
                        name    => $domain,
                        type    => $type,
                        %data
                    );
                    push(@{$records_by_type->{$type}}, $record);
                    push(@$records, $record);
                }
            }
            elsif (not ref($record_struct)) {
                # TIMEOUT, RCODE#, NO-TXT-SYNTHESIS
                if ($record_struct =~ /^(TIMEOUT|RCODE[1-5])$/) {
                    $records_by_type->{ANY} = $record_struct;
                }
                elsif ($record_struct eq 'NO-TXT-SYNTHESIS') {
                    $txt_rr_synthesis = FALSE;
                }
                else {
                    die("Unexpected record token");
                }
            }
            else {
                # Unexpected record structure!
                die("Unexpected record structure");
            }
        }
        
        # TXT RR synthesis:
        if (
            $txt_rr_synthesis and
            defined($records_by_type->{SPF}) and
            not defined($records_by_type->{TXT})
        ) {
            foreach my $spf_record (@{$records_by_type->{SPF}}) {
                my $txt_record = Net::DNS::RR->new(
                    name            => $spf_record->name,
                    type            => 'TXT',
                    char_str_list   => [$spf_record->char_str_list]
                );
                push(@{$records_by_type->{TXT}}, $txt_record);
            }
        }
    }
    
    return $self;
}

=item B<new_from_yaml($yaml_text, %options)>: returns I<Mail::SPF::Test::Scenario>

Creates a new SPF test-suite scenario object from the given YAML string.

=cut

sub new_from_yaml {
    my ($self, $yaml_text, %options) = @_;
    require YAML::Loader;
    my $yaml_loader = YAML::Loader->new();
    my ($raw_yaml_struct) = $yaml_loader->load($yaml_text);
    $self = $self->new_from_yaml_struct($raw_yaml_struct);
    return $self;
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<as_yaml>: returns I<string>

Returns the test-suite scenario formatted as a YAML document.

=cut

sub as_yaml {
    my ($self) = @_;
    require YAML::Dumper;
    my $yaml_dumper = YAML::Dumper->new();
    my $raw_yaml_data = {
        description => $self->{description},
        tests       => $self->{test_cases},
        zonedata    => $self->{records_by_domain}
    };
    return $yaml_dumper($raw_yaml_data);
}

=item B<description>: returns I<string>

Returns the description of the test-suite scenario.

=cut

# Make read-only accessor:
__PACKAGE__->make_accessor('description', TRUE);

=item B<test_cases>: returns I<list> of I<Mail::SPF::Test::Case>

Returns a list of the test-suite scenario object's test case objects.

=cut

sub test_cases {
    my ($self) = @_;
    return values(%{$self->{test_cases}});
}

=item B<spec_refs>: returns I<list> of I<string>

=item B<spec_refs($granularity)>: returns I<list> of I<string>

Returns a combined and sorted list of the specification references of all the
test-suite scenario object's test case objects.

See L<Mail::SPF::Test::Case/spec_refs> for how to specify a granularity for the
specification references.

=cut

sub spec_refs {
    my ($self, $granularity) = @_;
    my @refs = map($_->spec_refs($granularity), $self->test_cases);
    my %unique_refs; @unique_refs{@refs} = ();
    {
        no warnings 'numeric';
        @refs = sort { ($a =~ /^\d/ and $b =~ /^\d/ and $a <=> $b) or ($a cmp $b) } keys(%unique_refs);;
    }
    return @refs;
}

=item B<records>: returns I<list> of I<Net::DNS::RR> and DNS status tokens

Returns a list of the test-suite scenario object's DNS RR objects and DNS
status tokens.

See L</records_for_domain> for the description of DNS RR objects and DNS status
tokens.

=cut

sub records {
    my ($self) = @_;
    return @{$self->{records}};
}

=item B<records_for_domain($domain)>: returns I<list> of I<Net::DNS::RR> and DNS status tokens

=item B<records_for_domain($domain, $type)>: returns I<list> of I<Net::DNS::RR> and DNS status tokens

Returns either the DNS RR objects of the test-suite scenario object that match
the given domain and, if specified, RR type, or a DNS status token.

DNS RR objects are of type I<Net::DNS::RR>.  A DNS status token is any of
B<'TIMEOUT'> or B<'RCODE#'> (where B<#> is a digit from 1 to 5).

=cut

sub records_for_domain {
    my ($self, $domain, $type) = @_;
    
    defined($domain)
        or return ();  # Invalid domain.
    $domain =~ s/^(.*?)\.?$/\L$1/;
    $type ||= 'ANY';
    
    my $recordset = $self->{records_by_domain}->{$domain}
        or return ();  # Unknown domain.
    
    # ANY queries are unsupported., return RCODE 4 ("not implemented"):
    return 'RCODE4'
        if $type eq 'ANY';
    
    # Use TIMEOUT/RCODE# entry meant for requested type:
    return $recordset->{$type}
        if defined($recordset->{$type}) and not ref($recordset->{$type});
    # Use RRs applicable specifically to the requested type:
    return @{$recordset->{$type}}
        if ref($recordset->{$type}) eq 'ARRAY';
    
    # Use TIMEOUT/RCODE# entry meant for any type:
    return $recordset->{ANY}
        if  defined($recordset->{ANY}) and not ref($recordset->{ANY});
    # Use RRs applicable to any type:
    return @{$recordset->{ANY}}
        if ref($recordset->{ANY}) eq 'ARRAY';
    
    return ();
}

=back

=head1 SEE ALSO

L<Mail::SPF::Test>

For availability, support, and license information, see the README file
included with Mail::SPF::Test.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
