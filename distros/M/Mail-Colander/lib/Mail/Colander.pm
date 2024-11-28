package Mail::Colander;
use v5.24;
use Moo;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

use Data::Annotation;
use Storable qw< dclone >;
use Scalar::Util qw< blessed >;

use namespace::clean;

has annotator => (
   is => 'ro',
   coerce => sub ($in) {
      return $in if blessed($in);
      $in = dclone($in);
      #use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;
      #die Dumper($in);
      my $parse_ctx = $in->{'condition-parse-context'} //= {};
      my $prefixes = $parse_ctx->{'locator-relative-prefixes'} //= [];
      push $prefixes->@*, 'Mail::Colander::AnnotationBuiltins';
      return Data::Annotation->new($in)->inflate_chains;
   },
   handles => [qw< description has_chain_for >]
);

sub policy_for ($self, $chain, $element) {
   return $self->annotator->evaluate($chain, $element);
}

1;
