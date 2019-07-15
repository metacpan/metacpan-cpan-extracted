package File::Serialize;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: DWIM file serialization/deserialization
$File::Serialize::VERSION = '1.3.0';
use v5.16.0;

use feature 'current_sub';

use strict;
use warnings;

use Class::Load qw/ load_class /;
use List::AllUtils qw/ uniq /;
use List::Util 1.41 qw/ pairgrep first none any pairmap /;
use Path::Tiny;

use Module::Pluggable
   require => 1,
   sub_name => '_all_serializers',
   search_path => __PACKAGE__ . '::Serializer'
;

use parent 'Exporter::Tiny';

our @EXPORT = qw/ serialize_file deserialize_file transerialize_file /;

sub _generate_serialize_file {
    my( undef, undef, undef, $global )= @_;

    return sub {
        my( $file, $content, $options ) = @_;

        $options = { format => $options } if $options and not ref $options;

        $options = { %$global, %{ $options||{} } } if $global;
        # default to utf8 => 1
        $options->{utf8} //= 1;
        $options->{allow_nonref} //= 1;
        $options->{pretty} //= 1;
        $options->{canonical} //= 1;

        $file = path($file) unless $file =~ /^-/ or ref $file eq 'SCALAR';

        my $serializer = _serializer($file, $options);

        $file = path( join '.', $file, $serializer->extension )
            if $options->{add_extension} and $file ne '-'
                and ref $file ne 'SCALAR';

        my $method = $options->{utf8} ? 'spew_utf8' : 'spew';

        my $serialized = $serializer->serialize($content,$options);

        return print $serialized if $file eq '-';

        if( ref $file eq 'SCALAR' ) {
            $$file = $serialized;
        }
        else {
            $file->$method($serialized);
        }
    }
}

sub _generate_deserialize_file {
    my( undef, undef, undef, $global ) = @_;

    return sub {
        my( $file, $options ) = @_;

        $file = path($file) unless $file eq '-' or ref $file eq 'SCALAR';

        $options = { %$global, %{ $options||{} } } if $global;
        $options->{utf8} //= 1;
        $options->{allow_nonref} //= 1;

        my $method = 'slurp' . ( '_utf8' ) x !! $options->{utf8};

        my $serializer = _serializer($file, $options);

        $file = path( join '.', $file, $serializer->extension )
            if $options->{add_extension} and $file ne '-' and ref $file ne 'SCALAR';

        return $serializer->deserialize(
            $file =~ /^-/ ? do { local $/ = <STDIN> }
          : ref $file eq 'SCALAR' ? $$file
          : $file->$method,
            $options
        );
    }
}

sub _generate_transerialize_file {

    my $serialize_file = _generate_serialize_file(@_);
    my $deserialize_file = _generate_deserialize_file(@_);


    return sub {
        my( $in, @chain ) = @_;
        my $data = ref($in) ? $in : $deserialize_file->($in);

        while( my $step = shift @chain) {
            if ( ref $step eq 'CODE' ) {
                local $_ = $data;
                $data = $step->($data);
            }
            elsif ( ref $step eq 'ARRAY' ) {
                die "subranch step can only be the last step of the chain"
                    if @chain;
                for my $branch( @$step ) {
                    __SUB__->($data,@$branch);
                }
            }
            elsif ( not ref $step or ref($step) =~ /Path::Tiny/ ) {
                die "filename '$step' not at the end of the chain"
                    unless @chain <= 1;

                $serialize_file->(  $step, $data, shift @chain );
            }
            elsif ( ref $step eq 'HASH' ) {
                while( my ($f,$o) = each %$step ) {
                    $serialize_file->($f,$data,$o);
                }
            }
            elsif ( ref $step eq 'SCALAR' ) {
                $$step = $data;
            }
            else {
                die "wrong chain argument";
            }
        }

    }
}

sub _all_operative_formats {
    my $self = shift;
    return uniq map { $_->extension } $self->_all_operative_formats;
}

sub _all_operative_serializers {
    sort {
        $b->precedence <=> $a->precedence
            or
        $a cmp $b
    }
    grep { $_->is_operative }
    grep { $_->precedence }
    __PACKAGE__->_all_serializers;
}

sub _serializer {
    my( $self, $options ) = @_;

    no warnings qw/ uninitialized /;

    my $serializers = $options->{serializers} || [ __PACKAGE__->_all_operative_serializers ];
    s/^\+/File::Serialize::Serializer::/ for @$serializers;

    my $format = $options->{format} || ( ( ref $self ? $self->basename : $self ) =~ /\.(\w+)$/ )[0];

    return( first { $_->does_extension($format) } @$serializers
            or die "no serializer found for $format"
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Serialize - DWIM file serialization/deserialization

=head1 VERSION

version 1.3.0

=head1 SYNOPSIS

    use File::Serialize { pretty => 1 };

    my $data = { foo => 'bar' };

    serialize_file '/path/to/file.json' => $data;

    ...;

    $data_copy = deserialize_file '/path/to/file.json';

=head1 DESCRIPTION

I<File::Serialize> provides a common, simple interface to
file serialization -- you provide the file path, the data to serialized, and 
the module takes care of the rest. Even the serialization format, unless 
specified
explicitly as part of the options, is detected from the file extension.

=head1 IMPORT

I<File::Serialize> imports the three functions 
C<serialize_file>, C<deserialize_file> and C<transerialize_file> into the current namespace.
A default set of options can be set for both by passing a hashref as
an argument to the 'use' statement.

    use File::Serialize { pretty => 1 };

=head1 SUPPORTED SERIALIZERS

File::Serialize will pick the serializer to use based on
the extension of the filename or the explicitly given C<format>.
If several serializers are registered for the format,
the available serializer with the highest precedence number will
be used.

=over

=item YAML

L<File::Serialize::Serialize::YAML::Tiny>

=item JSON

L<File::Serialize::Serializer::JSON::MaybeXS>

=item TOML

L<File::Serialize::Serializer::TOML>

=item XML

L<File::Serialize::Serializer::XML::Simple>

=item jsony 

L<File::Serialize::Serializer::JSONY>

=back

=head1 OPTIONS

I<File::Serialize> recognizes a set of options that, if applicable,
will be passed to the serializer.

=over

=item format => $serializer

Explicitly provides the serializer to use.

    my $data = deserialize_file $path, { format => 'json' };

=item add_extension => $boolean

If true, the canonical extension of the serializing format will be 
appended to the file. Requires the parameter C<format> to be given as well.

    # will create 'foo.yml', 'foo.json' and 'foo.toml'
    serialize_file 'foo', $data, { format => $_, add_extension => 1 } 
        for qw/ yaml json toml /;

=item pretty => $boolean

The serialization will be formatted for human consumption.

=item canonical => $boolean

Serializes the data using its canonical representation.

=item utf8 => $boolean

If set to a C<true> value, file will be read/written out using L<Path::Tiny>'s C<slurp_utf8> and C<spew_utf8>
method ( which sets a C<binmode> of C<:encoding(UTF-8)>). Otherwise,
L<Path::Tiny>'s C<slurp> and C<spew> methods are used.

Defaults to being C<true> because, after all, this is the twenty-first century.

=item allow_nonref => $boolean

If set to true, allow to serialize non-ref data. 

Defaults to C<true>.

=back

=head1 FUNCTIONS

=head2 serialize_file $path, $data, $options

    my $data = { foo => 'bar' };

    serialize_file '/path/to/file.json' => $data;

If the C<$path> is 'C<->', the serialized data will be printed
to STDOUT. If it a scalar ref, the serialized data will be assigned
to that variable.

    serialize_file \my $serialized => $data;

    print $serialized;

=head2 deserialize_file $path, $options

    my $data = deserialize_file '/path/to/file.json';

If the C<$path> is 'C<->', the serialized data will be read from
STDIN. If it a scalar ref, the serialized data will be read
from that variable.

    my $json = '{"foo":1}';
    my $data = deserialize_file \$json;

=head2 transerialize_file $input, @transformation_chain

C<transerialize_file> is a convenient wrapper that allows you to
deserialize a file, apply any number of transformations to its 
content and re-serialize the result.

C<$input> can be a filename, a L<Path::Tiny> object or the raw data 
structure to be worked on.

    transerialize_file 'foo.json' => 'foo.yaml';
    
    # equivalent to
    serialize_file 'foo.yaml' => deserialize_file 'foo.json'

Each element of the C<@transformation_chain> can be

=over

=item $coderef

A transformation step. The current data is available both via C<$_> and
as the first argument to the sub,
and the transformed data is going to be whatever the sub returns.

    my $data = {
        tshirt => { price => 18 },
        hoodie => { price => 50 },
    };

    transerialize_file $data => sub {
        my %inventory = %$_;

        +{ %inventory{ grep { $inventory{$_}{price} <= 20 } keys %inventory } }

    } => 'inexpensive.json';

    # chaining transforms
    transerialize_file $data 
        => sub { 
            my %inventory = %$_; 
            +{ map { $_ => $inventory{$_}{price} } keys %inventory } }
        => sub {
            my %inventory = %$_;
            +{ %inventory{ grep { $inventory{$_} <= 20 } keys %inventory } }
        } => 'inexpensive.json';

    # same as above, but with Perl 5.20 signatures and List::Util pair*
    # helpers
    transerialize_file $data 
        => sub($inventory) { +{ pairmap  { $a => $b->{price} } %$inventory } }
        => sub($inventory) { +{ pairgrep { $b <= 20 }          %$inventory } } 
        => 'inexpensive.json';

=item \%destinations

A hashref of destination file with their options. The current state of the data will
be serialized to those destination. If no options need to be passed, the 
value can be C<undef>.

    transerialize_file $data => { 
        'beginning.json' => { pretty => 1 },
        'beginning.yml'  => undef
    } => sub { ... } => {
        'end.json' => { pretty => 1 },
        'end.yml'  => undef
    };

=item [ \@subchain1, \@subchain2, ... ] 

Run the subchains given in C<@branches> on the current data. Must be the last
step of the chain.

    my @data = 1..10;

    transerialize_file \@data 
        => { 'all.json' => undef }
        => [
           [ sub { [ grep { $_ % 2 } @$_ ] }     => 'odd.json'  ],
           [ sub { [ grep { not $_ % 2 } @$_ ] } => 'even.json' ],
        ];

=item ( $filename, $options )

Has to be the final step(s) of the chain. Just like the arguments
of C<serialize_file>. C<$filename> can be a string or a L<Path::Tiny> object.
C<$options> is optional.

=item \$result

Has to be the final step of the chain. Will assign the transformed data
to C<$result> instead of serializing to a file.

=back

=head1 ADDING A SERIALIZER

Serializers are added by creating a F<File::Serialize::Serializer::*> class that
implement the L<File::Serialize::Serializer> role. See the documentation for the
role for more details.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
