package JSON::DJARE::Writer;
$JSON::DJARE::Writer::VERSION = '0.02';
use strict;
use warnings;
use Moo;
use JSON qw();
use Carp qw/croak/;
our @CARP_NOT;

=head1 NAME

JSON::DJARE::Writer

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Simple writer of DJARE documents

=head1 SYNOPSIS

  my $writer = JSON::DJARE::Writer->new(
      djare_version  => '0.0.2', # required
      meta_version   => '0.1.1', # required

      meta_from      => 'my-api' # optional
      auto_timestamp => 1,       # default 0, also accepts coderef
  );

  my $success = $writer->data(
      { foo => 'bar' },
      from => 'my-other-api' # optional if set in constructor
  );

  my $error = $writer->error(
      "something went wrong", # title
      schema => 'schema-id',  # optional schema
      id => "12345",          # other optional fields
  );

  ### JSON

  # There's a _json version of both producer methods that returns a JSON string
  my $json = $writer->data_json(
  my $json = $writer->error_json(

  # But if you want to mess around with the document you've created before
  # encoding it, there's a to_json method that'll help
  my $doc = $writer->data(
  $doc->{'meta'}->{'trace'} = "x12345";
  my $json = $writer->to_json( $doc )

=head1 DJARE

DJARE is documented
L<https://github.com/pjlsergeant/dumb-json-api-response-envelope|elsewhere>
and this document neither discusses or documents DJARE itself.

=head1 METHODS

=head2 new

Instantiates a new writer object.

Options:

=over 4

=item * C<djare_version> - required. The version of DJARE you want to produce.
The only possible value for this (at the time of writing) is C<0.0.2>.

=item * C<meta_version> - required. The version number to include in the DJARE
`meta/version` section. This is a L<SemVer|https://semver.org>.

=item * C<meta_from> - optional. A DJARE document needs a C<meta/from> field.
You can either specify this for all documents this object will produce here, or
you can set it at document creation time

=item * C<meta_schema> - optional. A DJARE document may include a
C<meta/schema> field. You can either specify this for all documents this object
will produce here, or you can set it at document creation time

=back

=cut

sub new {
    my ( $class, %options ) = @_;

    my $djare_version = delete $options{'djare_version'};
    croak "new() requires `djare_version`" unless $djare_version;
    croak "Only supported `djare_version` is 0.0.2"
      unless $djare_version eq '0.0.2';

    my $meta_version = delete $options{'meta_version'};
    croak "new() requires `meta_version`" unless $meta_version;
    croak "`meta_version` needs to be a semver"
      unless $meta_version =~
      m/^(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$/;

    my $meta_presets = {
        version => $meta_version,
        djare   => $djare_version,
    };
    for (qw/from schema trace/) {
        my $value = delete $options{"meta_$_"};
        $meta_presets->{$_} = $value if defined $value;
    }

    my $self = { meta_presets => $meta_presets };
    $self->{'_json'} ||= JSON->new->allow_nonref->canonical;

    for my $method (qw/auto_timestamp/) {
        if ( my $method_value = delete $options{$method} ) {
            if ( ref $method_value eq 'CODE' ) {
                $self->{$method} = $method_value;
            }
            elsif ( ref $method_value ) {
                croak "`$method` should either be a boolean or a coderef";
            }
            else {
                $self->{$method} = sub {
                    $self->$method(@_);
                };
            }
        }
    }

    if ( my $error_keys = join '; ', sort keys %options ) {
        croak "Unknown options: [$error_keys]";
    }

    bless $self, $class;
}

=head2 data

=head2 data_json

 ->data( payload, options )
 ->data( { quis => 'ego' }, from => 'scrambles' )

First argument is the data payload, and the other arguments are a hash of
options, of which the only definable one is C<from>, for overriding
C<meta/from>. Returns a Perl hashref.

C<data_json> is the same thing, but returns JSON.

=cut

sub data {
    my ( $self, $data, %options ) = @_;

    my $meta = $self->_meta( from => delete $options{'from'} );
    $self->_check_no_bad_options(%options);

    return {
        meta => $meta,
        data => $data
    };
}

sub data_json {
    my $self = shift;
    $self->to_json( $self->data(@_) );
}

=head2 error

=head2 error_json

 ->error( title, options )
 ->error( "didn't work", id => 4532 )

First argument is the data payload, and the other arguments are a hash of
options, of which the only definable one is C<from>, for overriding
C<meta/from>. Returns a Perl hashref.

All keys will be stringified except C<trace>, except undefined keys, which will
be dropped rather than turned into an empty string.

C<data_json> is the same thing, but returns JSON.

=cut

sub error {
    my ( $self, $title, %options ) = @_;

    my $meta  = $self->_meta( from => delete $options{'from'} );
    my %error = ( title => "$title" );

    # Trace gets special handling because it's allowed to be anything at all,
    # although I'm taking the executive decision that we won't set it if undef
    $error{'trace'} = delete $options{'trace'};
    delete $error{'trace'} unless defined $error{'trace'};

    # These get stringified if they exist _and_ they have a value. They're not
    # allowed to have undef values in the spec
    for my $key ( qw/id code detail/ ) {
        my $value = delete $options{ $key };
        if ( defined $value ) {
            $error{ $key } = "$value";
        }
    }

    $self->_check_no_bad_options(%options);

    return {
        meta  => $meta,
        error => \%error
    };
}

sub error_json {
    my $self = shift;
    $self->to_json( $self->error(@_) );
}

=head2 to_json

Convenience method to the same JSON stringifier the C<*_json> methods use.

Literally just: C<$self->{'_json'}->encode($payload)>

=cut

sub to_json {
    my ( $self, $payload ) = @_;
    return $self->{'_json'}->encode($payload);
}

=head2 auto_timestamp

The default timestamp creator, which is what's used if you instantiate with
C<<auto_timestamp => 1>>. Uses C<gmtime(time)> as its base.

=cut

sub auto_timestamp {
    my $self = shift;
    my ( $sec, $min, $hour, $mday, $mon, $year ) = gmtime(time);
    return sprintf(
        '%04d-%02d-%02d %02d:%02d:%02d+00:00',
        $year + 1900,
        $mon + 1, $mday, $hour, $min, $sec
    );
}

sub _meta {
    my ( $self, %options ) = @_;

    my $meta = { %{ $self->{'meta_presets'} } };

    $meta->{'from'} = delete $options{'from'}
      // $self->{'meta_presets'}->{'from'}
      // croak "`from` must be provided or preset";
    $meta->{'from'} = "" . $meta->{'from'};

    if ( $self->{'auto_timestamp'} ) {
        $meta->{'timestamp'} = $self->{'auto_timestamp'}->();
    }

    $self->_check_no_bad_options(%options);

    return $meta;
}

sub _check_no_bad_options {
    my ( $self, %options ) = @_;
    if ( my $error_keys = join '; ', sort keys %options ) {
        croak "Unknown options: [$error_keys]";
    }
}

1;
