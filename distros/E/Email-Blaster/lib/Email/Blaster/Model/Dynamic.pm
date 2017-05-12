
package Email::Blaster::Model::Dynamic;

use strict;
use warnings 'all';
use Email::Blaster::ConfigLoader;


#==============================================================================
sub import
{
  my $caller = caller(0);
  # Use dynamic inheritance.  Because this is Perl.  Because we can.
  my $config = Email::Blaster::ConfigLoader->load();
  (my $pkg = $config->database->orm_base_class . ".pm") =~ s/::/\//g;
  require $pkg unless $INC{$pkg};
  no strict 'refs';
  push @{"$caller\::ISA"}, $config->database->orm_base_class;
  $caller->connection(
    $config->database->dsn,
    $config->database->username,
    $config->database->password
  );
}# end import()

1;# return true:

