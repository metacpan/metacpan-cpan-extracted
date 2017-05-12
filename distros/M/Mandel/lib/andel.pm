package andel;

=head1 NAME

andel - Oneliner Mandel magic

=head1 SYNOPSIS

  perl -Mandel=MyModel -E'say c("users", j shift)->in_storage' '{"name":"joe"}'
  perl -Mandel=MyModel -E'say c("users", { name => "joe" })->in_storage'
  perl -Mandel=MyModel,db_name -E'say c("users")->count'
  perl -Mandel=MyModel,mongodb://hostname/db_name -E'say c("users")->count'

=cut

use Mojo::Base -strict;

my $mandel;

=head1 EXPORTED FUNCTIONS

=head2 c

  $collection = c("collection_name");
  $obj = c("collection_name", \%create_args);

Alias for

  $mandel->collection("collection_name");

Or

  $mandel->collection("collection_name")->create(\%create_args)->save;

=cut

sub c {
  my $name = shift or die "Usage: c('collection_name')";
  my $collection = $mandel->collection($name);

  if (@_ and ref $_[0] eq 'HASH') {
    return $collection->create($_[0])->save;
  }

  return $collection;
}

=head2 j

See L<Mojo::JSON/j>.

=head1 METHODS

=head2 import

See L</SYNOPSIS>.

=cut

sub import {
  my $class  = shift;
  my $caller = caller;

  strict->import;
  warnings->import;

  $class->_setup(@_) if @_;

  no strict 'refs';
  *{"$caller\::c"} = \&c;
  *{"$caller\::j"} = \&Mojo::JSON::j;
}

sub _setup {
  my ($class, $model, @connect) = @_;
  eval "use $model; 1" or die "use $model: $@";
  $connect[0] = "mongodb://localhost/$connect[0]" if @connect and $connect[0] !~ /^mongodb:/;
  $mandel = $model->connect(@connect);
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
