package MARC::Schema;

use strict;
use warnings;

our $VERSION = '0.16';

use Cpanel::JSON::XS;
use File::Share ':all';
use File::Slurper 'read_binary';
use Scalar::Util qw(reftype);

sub new {
    my ($class, $arg_ref) = @_;
    my $self = $arg_ref // {};
    bless $self, $class;
    $self->_initialize();
    return $self;
}

sub _initialize {
    my ($self) = shift;
    if (!$self->{fields}) {
        $self->{fields} = $self->_load_schema();
    }
    return;
}

sub _load_schema {
    my ($self) = shift;
    my $json;
    if ($self->{file}) {
        $json = read_binary($self->{file});
    }
    else {
        $self->{file} = dist_file('MARC-Schema', 'marc-schema.json');
        $json = read_binary($self->{file});
    }
    my $schema = decode_json($json);

    return $schema->{fields};
}

sub check {
    my ($self, $record, %options) = @_;

    $record = $record->{record} if reftype $record eq 'HASH';

    $options{counter} = {};
    return map {$self->check_field($_, %options)} @$record;
}

sub check_field {
    my ($self, $field, %options) = @_;

    my $tag = $field->[0];

    my $spec = $self->{fields}->{$tag};

    if (!$spec) {
        if (!$options{ignore_unknown_fields}) {
            return ({tag => $tag, error => 'unknown field', type => 'field'});
        }
        else {
            return ();
        }
    }

    if ($options{counter} && !$spec->{repeatable}) {
        if ($options{counter}{$field->[0]}++) {
            return (
                {
                    tag   => $tag,
                    error => 'field is not repeatable',
                    type  => 'field',
                }
            );
        }
    }

    my @errors;
    if ($spec->{subfields}) {
        my %sfcounter;
        my (undef, undef, undef, @subfields) = @$field;
        while (@subfields) {
            my ($code, undef) = splice @subfields, 0, 2;
            my $sfspec = $spec->{subfields}->{$code};

            if ($sfspec) {
                if (!$sfspec->{repeatable} && $sfcounter{$code}++) {
                    push @errors,
                        {
                        tag   => $tag,
                        error => 'subfield is not repeatable',
                        type  => 'subfield',
                        value => $code,
                        };
                }
            }
            elsif (!$options{ignore_unknown_subfields}) {
                push @errors,
                    {
                    tag   => $tag,
                    error => "unknown subfield",
                    type  => 'subfield',
                    value => $code,
                    };
            }
        }
    }

    if ($spec->{indicator1}) {
        my (undef, $code, @other) = @$field;
        $code //= ' ';
        my (@matches)
            = grep {$code =~ /^[$_]/} keys %{$spec->{indicator1}->{codes}};

        if (@matches > 0) {

            # everything is ok
        }
        else {
            push @errors,
                {
                tag   => $tag,
                error => 'unknown first indicator',
                type  => 'indicator',
                value => $code,
                };
        }
    }

    if ($spec->{indicator2}) {
        my (undef, undef, $code, @other) = @$field;
        $code //= ' ';
        my (@matches)
            = grep {$code =~ /^[$_]/} keys %{$spec->{indicator2}->{codes}};

        if (@matches > 0) {

            # everything is ok
        }
        else {
            push @errors,
                {
                tag   => $tag,
                error => 'unknown second indicator',
                type  => 'indicator',
                value => $code,
                };
        }
    }

    return @errors;
}

1;
__END__

=encoding utf-8

=head1 NAME

MARC::Schema - Specification of the MARC21 format

=begin markdown

[![Linux build status](https://github.com/jorol/MARC-Schema/actions/workflows/linux.yml/badge.svg)](https://github.com/jorol/MARC-Schema/actions/workflows/linux.yml)
[![Coverage Status](https://coveralls.io/repos/jorol/MARC-Schema/badge.png?branch=master)](https://coveralls.io/r/jorol/MARC-Schema?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/MARC-Schema.png)](http://cpants.cpanauthors.org/dist/MARC-Schema)
[![CPAN version](https://badge.fury.io/pl/MARC-Schema.png)](http://badge.fury.io/pl/MARC-Schema)

=end markdown

=head1 SYNOPSIS

    # in Perl
    use MARC::Schema;

    my $record = {
        _id    => 'fol05865967',
        record => [
            [ 'LDR', undef, undef, '_', '00661nam  22002538a 4500' ],
            [ '001', undef, undef, '_', 'fol05865967' ],
            [ '001', undef, undef, '_', 'field is not repeatable' ],
            [   '245', '1', '0', 'a', 'Programming Perl /',
                'c', 'Larry Wall, Tom Christiansen & Jon Orwant.',
                'a', 'subfield is not repeatable',
                'x', 'unknown subfield',
            ],
            [ '999', undef, undef, '_', 'not a standard field']
        ]
    };

    # load default schema
    my $schema = MARC::Schema->new();

    # load custom schema from file
    my $schema = MARC::Schema->new({ file => share/marc-schema.json });


    # load custom schema
    my $schema = MARC::Schema->new(
        {   fields => {
                '001' => { label => 'Control Number', repetable => 0 }
            }
        }
    );
    my @check = $schema->check($record);

    # via the command line
    $ marcvalidate t/camel.mrc
    $ marcvalidate --schema marc_schema.json t/camel.mrc
    $ marcvalidate --type XML marc.xml

=head1 DESCRIPTION

MARC::Schema defines a set of MARC21 fields and subfields to validate Catmandu::MARC records. A schema is given as hash reference such as:

    {   fields => {
            LDR => {
                positions =>
                    [ { position => '00-04', label => 'Record length' } ],
                repeatable => 0,
            },
            '001' => { label => 'Control Number', repeatable => 0 }
        }
    }

For a more detailed description of the (default) schema see L<MARC21 structure in JSON|https://pkiraly.github.io/2018/01/28/marc21-in-json/>.

=head1 METHODS

=head2 check( $record [, %options ] )

Check whether a given L<"Catmandu::Importer::MARC"|Catmandu::Importer::MARC/"EXAMPLE ITEM"> or L<"MARC::Parser::*"|https://metacpan.org/search?q=%22MARC%3A%3AParser%22> record confirms to the schema and return a list of detected violations. Possible options include:

=over

=item ignore_unknown_fields

Don't report fields not included in the schema.

=item ignore_unknown_subfields

Don't report subfields not included in the schema.

=back

Errors are given as list of hash references with keys C<error>, C<tag>, 
C<type> and C<value> of the violated field. C<error> contains a 
human-readable error message for each violated field and/or subfield.

=head2 check_field( $field [, %options ] )

Check whether a MARC21 field confirms to the schema. Use same options as method C<check>.

=head1 AUTHOR

Johann Rolschewski E<lt>jorol@cpan.orgE<gt>

=head1 CONTRIBUTORS

Patrick Hochstenbach

Steve Rogerson

=head1 COPYRIGHT

Copyright 2018- Johann Rolschewski

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu::Validator>

L<JSON::Schema>

L<PICA::Schema>

L<MARC::Lint>

=head1 ACKNOWLEDGEMENT

MARC::Schema uses the MARC21 schema developed by L<Péter Király|https://github.com/pkiraly> as default. For more information see L<"Metadata assessment for MARC records"|https://github.com/pkiraly/metadata-qa-marc> and L<"MARC21 structure in JSON"|https://pkiraly.github.io/2018/01/28/marc21-in-json/>.

=cut
