package Devel::REPL::Plugin::TrepanShell;

use Devel::REPL::Plugin;
use namespace::clean -except => [ 'meta' ];

has 'history' => (
   isa => 'ArrayRef', is => 'rw', required => 1, lazy => 1,
   default => sub { [] }
);

around 'read' => sub {
   my $orig = shift;
   my ($self, @args) = @_;
   my $line = $self->$orig(@args);
   if (defined $line) {
       if ($line =~ m/^%(.*)$/) {
	   my $fn = $1;
	   die "$1";
       }
   }
   return $line;
};

1;

__END__

=head1 NAME

Devel::REPL::Plugin::TrepanShell - Add '%' commands to call back Trepan in a Devel::REPL shell invoked from Devel::Trepan

=cut

