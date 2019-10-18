package JSON::Slurper;
use strict;
use warnings;
use Carp ();
use Exporter::Shiny qw(slurp_json spurt_json);
use File::Basename ();
use File::Slurper  ();
use Scalar::Util   ();

our $VERSION     = '0.10';
our %EXPORT_TAGS = (
    std      => [qw(slurp_json spurt_json)],
    std_auto => [qw(-auto_ext slurp_json spurt_json)],
    slurp_auto => [qw(-auto_ext slurp_json)],
    spurt_auto => [qw(-auto_ext spurt_json)],
);

use constant JSON_XS => $ENV{JSON_SLURPER_NO_JSON_XS}                                          ? do { require JSON::PP; undef }
                     : eval { require Cpanel::JSON::XS; Cpanel::JSON::XS->VERSION('4.09'); 1 } ? 1
                     : do { require JSON::PP; undef };
my $DEFAULT_ENCODER;

sub new {
    my ($class, %args) = @_;

    my $encoder;
    if (exists $args{encoder}) {
        $encoder = delete $args{encoder};
        Carp::croak 'encoder must be an object that can encode and decode'
          unless Scalar::Util::blessed($encoder) && $encoder->can('encode') && $encoder->can('decode');
    } else {
        $encoder = $DEFAULT_ENCODER ||=
          JSON_XS
          ? Cpanel::JSON::XS->new->utf8->pretty->canonical->allow_nonref->allow_blessed->convert_blessed->escape_slash
          ->stringify_infnan
          : JSON::PP->new->utf8->pretty->canonical->allow_nonref->allow_blessed->convert_blessed->escape_slash;
    }

    my $auto_ext = delete $args{auto_ext};

    Carp::croak "invalid constructor arguments provided: @{[join ',', keys %args]}" if %args;

    bless [$encoder, $auto_ext], $class;
}

sub _generate_slurp_json {
    my $auto_ext = exists $_[3]->{auto_ext};

    return sub ($;@) {
        my ($filename, $encoder) = @_;

        if (defined $encoder) {
            Carp::croak 'invalid encoder'
              unless Scalar::Util::blessed($encoder)
              && $encoder->can('encode')
              && $encoder->can('decode');
        } else {
            $encoder = $DEFAULT_ENCODER ||=
              JSON_XS
              ? Cpanel::JSON::XS->new->utf8->pretty->canonical->allow_nonref->allow_blessed->convert_blessed
              ->escape_slash
              ->stringify_infnan
              : JSON::PP->new->utf8->pretty->canonical->allow_nonref->allow_blessed->convert_blessed->escape_slash;
        }

        my $wantarray = wantarray;
        unless (defined wantarray) {
            Carp::carp 'slurp_json requested without a used return value. Returning from slurp_json';
            return;
        }

        if ($auto_ext and not ((File::Basename::fileparse($filename, qr/\.[^.]*/xm))[2])) {
            $filename = "$filename.json";
        }

        my $slurped = $encoder->decode(File::Slurper::read_binary($filename));

        if ($wantarray and my $ref = ref $slurped) {
            return @$slurped if $ref eq 'ARRAY';
            return %$slurped if $ref eq 'HASH';
        }

        return $slurped;
    }
}

sub slurp {
    my ($self, $filename) = @_;

    my $wantarray = wantarray;
    unless (defined wantarray) {
        Carp::carp 'slurp requested without a used return value. Returning from slurp';
        return;
    }

    if ($self->[1] and not ((File::Basename::fileparse($filename, qr/\.[^.]*/xm))[2])) {
        $filename = "$filename.json";
    }

    my $slurped = $self->[0]->decode(File::Slurper::read_binary($filename));
    if ($wantarray and my $ref = ref $slurped) {
        return @$slurped if $ref eq 'ARRAY';
        return %$slurped if $ref eq 'HASH';
    }

    return $slurped;
}

sub _generate_spurt_json {
    my $auto_ext = exists $_[3]->{auto_ext};

    return sub ($$;@) {
        my ($data, $filename, $encoder) = @_;

        if (defined $encoder) {
            Carp::croak 'invalid encoder'
              unless Scalar::Util::blessed($encoder)
              && $encoder->can('encode')
              && $encoder->can('decode');
        } else {
            $encoder = $DEFAULT_ENCODER ||=
              JSON_XS
              ? Cpanel::JSON::XS->new->utf8->pretty->canonical->allow_nonref->allow_blessed->convert_blessed
              ->escape_slash
              ->stringify_infnan
              : JSON::PP->new->utf8->pretty->canonical->allow_nonref->allow_blessed->convert_blessed->escape_slash;
        }

        if ($auto_ext and not ((File::Basename::fileparse($filename, qr/\.[^.]*/xm))[2])) {
            $filename = "$filename.json";
        }

        File::Slurper::write_binary($filename, $encoder->encode($data));
    }
}

sub spurt {
    my ($self, $data, $filename) = @_;

    if ($self->[1] and not ((File::Basename::fileparse($filename, qr/\.[^.]*/xm))[2])) {
        $filename = "$filename.json";
    }

    File::Slurper::write_binary($filename, $self->[0]->encode($data));
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::Slurper - Convenient file slurping and spurting of data using JSON

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/JSON-Slurper"><img src="https://travis-ci.org/srchulo/JSON-Slurper.svg?branch=master"></a>

=head1 SYNOPSIS

  use JSON::Slurper qw(slurp_json spurt_json);
  # or
  use JSON::Slurper -std;

  my @people = (
    {
        name => 'Ralph',
        age => 19,
        favorite_food => 'Pizza',
    },
    {
        name => 'Sally',
        age => 23,
        favorite_food => 'French Fries',
    },
  );

  spurt_json \@people, 'people.json';

  my @people_from_file = slurp_json 'people.json';

  # or get as a reference
  my $people_from_file = slurp_json 'people.json';

  # Same as above with Object-Oriented interface
  my $json_slurper = JSON::Slurper->new;

  $json_slurper->spurt(\@people, 'people.json');

  my @people_from_file = $json_slurper->slurp('people.json');

  # or get as a reference
  my $people_from_file = $json_slurper->slurp('people.json');

  # use the -auto_ext flag so that ".json" is added as the
  # file extension if no file extension is present.
  use JSON::Slurper qw(-auto_ext slurp_json spurt_json);
  # or
  use JSON::Slurper -std_auto;

  # This saves to people.json
  spurt_json \@people, 'people';

  # This reads from people.json
  my @people_from_file = slurp_json 'people';

  # auto_ext can also be passed when using the object-oriented interface:
  my $json_slurper = JSON::Slurper->new(auto_ext => 1);

=head1 DESCRIPTION

JSON::Slurper is a convenient way to slurp/spurt (read/write) Perl data structures to and from JSON files. It tries to do what you mean, and allows you to provide your own JSON encoder/decoder if necessary.

=head1 DEFAULT ENCODER

Both the L</"FUNCTIONAL INTERFACE"> and the L</"OBJECT-ORIENTED INTERFACE"> use the same default encoders. You can provide your own encoder whether you use the L</"FUNCTIONAL INTERFACE"> or the L</"OBJECT-ORIENTED INTERFACE">.

=head2 Cpanel::JSON::XS

If you have the recommended L<Cpanel::JSON::XS> installed, this is the default used:

  Cpanel::JSON::XS->new
                  ->utf8
                  ->pretty
                  ->canonical
                  ->allow_nonref
                  ->allow_blessed
                  ->convert_blessed
                  ->escape_slash
                  ->stringify_infnan

=head2 JSON::PP

If you are using L<JSON::PP>, this is the default used:

  JSON::PP->new
          ->utf8
          ->pretty
          ->canonical
          ->allow_nonref
          ->allow_blessed
          ->convert_blessed
          ->escape_slash

=head1 FUNCTIONAL INTERFACE

=head2 -auto_ext

Passing the C<-auto_ext> flag with the imports causes C<.json> to be added to filenames when they have no extension.

  use JSON::Slurper qw(-auto_ext slurp_json spurt_json);

  # or

  use JSON::Slurper -std_auto;

  # Reads from "ref.json";
  my $ref = slurp_json 'ref';

  # If no extension is provided, ".json" will be used.
  # Writes to "ref.json";
  spurt_json $ref, 'ref';

  # If an extension is present, ".json" will not be added.
  # Writes to "ref.txt";
  spurt_json $ref, 'ref.txt';

=head2 slurp_json

=over 4

=item slurp_json $filename, [$json_encoder]

=back

  # values can be returned as refs
  my $ref = slurp_json 'ref.json';

  # or as an array or hash
  my @array = slurp_json 'array.json';

  my %hash = slurp_json 'hash.json';

  # You can pass your own JSON encoder
  my $ref = slurp_json 'ref.json', JSON::PP->new->ascii->pretty;

This reads in JSON from a file and returns it as a Perl data structure (a reference, an array, or a hash).
You can pass in your own JSON encoder/decoder as an optional argument, as long as it is blessed
and has C<encode> and C<decode> methods.

=head2 spurt_json

=over 4

=item spurt_json $data, $filename, [$json_encoder]

=back

  # data must be passed as references or scalars
  spurt_json \@array, 'ref.json';

  spurt_json 'string', 'ref.json';

  # pass anonymous array or hash refs
  spurt_json [1, 2, 3], 'ref.json';

  spurt_json {key => 'value'}, 'ref.json';

  # You can pass your own JSON encoder
  spurt_json $ref, 'ref.json', JSON::PP->new->ascii->pretty;

This reads in JSON from a file and returns it as a Perl data structure (a reference, an array, or a hash).
You can pass in your own JSON encoder/decoder as an optional argument, as long as it is blessed
and has C<encode> and C<decode> methods.

=head2 Export Tags

=head3 -std

This tag is the same as explicitly importing L</slurp_json> and L</spurt_json>:

  use JSON::Slurper -std;

  # same as

  use JSON::Slurper qw(slurp_json spurt_json);

=head3 -std_auto

This tag is the same as explicitly importing L</slurp_json> and L</spurt_json> and including the L</-auto_ext> flag:

  use JSON::Slurper -std_auto;

  # same as

  use JSON::Slurper qw(-auto_ext slurp_json spurt_json);

=head3 -slurp_auto

This tag is the same as explicitly importing L</slurp_json> and including the L</-auto_ext> flag:

  use JSON::Slurper -slurp_auto;

  # same as

  use JSON::Slurper qw(-auto_ext slurp_json);

=head3 -spurt_auto

This tag is the same as explicitly importing L</spurt_json> and including the L</-auto_ext> flag:

  use JSON::Slurper -spurt_auto;

  # same as

  use JSON::Slurper qw(-auto_ext spurt_json);

=head2 Shiny Importing

L<JSON::Slurper> uses L<Exporter::Shiny> for its exporting of subroutines. This allows for fancy importing, such as
renaming imported subroutines:

  use JSON::Slurper
    'slurp_json' => { -as => 'slurp_plz' },
    'spurt_json' => { -as => 'spurt_plz' };

  spurt_plz $ref, 'ref.json';
  my $ref_from_file = slurp_plz 'ref.json';

See L<Exporter::Tiny::Manual::Importing> for much more.

=head1 OBJECT-ORIENTED INTERFACE

=head2 new

  my $json_slurper = JSON::Slurper->new;

  # pass in your own JSON encoder/decoder
  my $json_slurper = JSON::Slurper->new(encoder => JSON::PP->new->ascii->pretty);

  # add ".json" to filenames that do not have an extension
  my $json_slurper = JSON::Slurper->new(auto_ext => 1);

L</new> creates a L<JSON::Slurper> object that allows you to use the L</"OBJECT-ORIENTED INTERFACE"> and call L</slurp> and L</spurt>.

=head3 encoder

You may provide your own encoder instead of the L</"DEFAULT ENCODER"> as long as it is blessed and has
C<encode> and C<decode> methods, like L<JSON::PP> or L<Cpanel::JSON::XS>.
This encoder will be used instead of the default one when calling L</slurp> and L</spurt>.

  my $json_slurper = JSON::Slurper->new(encoder => JSON::PP->new->ascii->pretty);

=head3 auto_ext

Passing C<auto_ext> with a C<true> value causes C<.json> to be added to filenames when they have no extension.

  my $json_slurper = JSON::Slurper->new(auto_ext => 1)

  # Reads from "ref.json";
  my $ref = $json_slurper->slurp('ref');

  # If no extension is provided, ".json" will be used.
  # Writes to "ref.json";
  $json_slurper->spurt($ref, 'ref');

  # If an extension is present, ".json" will not be added.
  # Writes to "ref.txt";
  $json_slurper->spurt($ref, 'ref.txt');

=head2 slurp

=over 4

=item slurp($filename)

=back

  # values can be returned as refs
  my $ref = $json_slurper->slurp('ref.json');

  # or as an array or hash
  my @array = $json_slurper->slurp('array.json');

  my %hash = $json_slurper->slurp('hash.json');

This reads in JSON from a file and returns it as a Perl data structure (a reference, an array, or a hash).

=head2 spurt

=over 4

=item spurt($data, $filename)

=back

  $json_slurper->spurt(\@array, 'array.json');

  $json_slurper->spurt(\%hash, 'hash.json');

This reads in JSON from a file and returns it as a Perl data structure (a reference, an array, or a hash).

=head1 TODO

More testing required.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<File::Slurper>

=item * L<JSON::PP>

=item * L<Cpanel::JSON::XS>

=item * L<Exporter::Tiny::Manual::Importing>

=back

=cut
