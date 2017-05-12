package Devel::REPL::Plugin::Perl5db;

use Devel::REPL::Plugin;
use Enbugger 'perl5db';
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
       if ($line =~ m/^%perl5db\s+(.*)$/) {
	   my $eval_code = $1;
	   $DB::eval_string = 
"package Devel::REPL::Plugin::Packages::DefaultScratchpad;
Enbugger->stop;  # newline is nice to have in showing code
$eval_code;
\$DB::signal = \$DB::single = \$DB::trace = 0;";
	   eval $DB::eval_string;
	   return $@;
       }
   }
   return $line;
};

1;

__END__

=head1 NAME

Devel::REPL::Plugin::TrepanShell - Add '%' commands to call back Trepan in a Devel::REPL shell invoked from Devel::Trepan

=cut

