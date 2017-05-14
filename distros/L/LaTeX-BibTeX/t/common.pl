use Carp;

my $err_file = 't/errors';

END { unlink $err_file }


sub setup_stderr
{
   open (SAVE_STDERR, ">&STDERR")
      || die "couldn't save stderr: $!\n";
   open (STDERR, ">$err_file")
      || die "couldn't redirect stderr to $err_file: $!\n";
   STDERR->autoflush (1);

#   $SIG{'__WARN__'} = sub { print SAVE_STDERR @_ };
   $SIG{'__DIE__'} = sub
   {
      open (STDERR, '>&=' . fileno (SAVE_STDERR));
      die @_;
   };
}

sub warnings
{
   my @err;
   open (ERR, $err_file) || die "couldn't open $err_file: $!\n";
   chomp (@err = <ERR>);
   close (ERR);
   open (STDERR, ">$err_file")
      || die "couldn't redirect stderr to $err_file: $!\n";
   STDERR->autoflush (1);
   if ($DEBUG)
   {
      printf "caught %d messages on stderr:\n", scalar @err;
      print join ("\n", @err) . "\n";
   }
   @err;
}

sub list_equal
{
   my ($eq, $a, $b) = @_;

   croak "list_equal: \$a and \$b not lists" 
      unless ref $a eq 'ARRAY' && ref $b eq 'ARRAY';

   return 0 unless @$a == @$b;          # compare lengths
   my @eq = map { &$eq ($a->[$_], $b->[$_]) } (0 .. $#$a);
   return 0 unless (grep ($_ == 1, @eq)) == @eq;
}

sub slist_equal
{
   my ($a, $b) = @_;
   list_equal (sub
               {
                  my ($a, $b) = @_;
                  (defined $a && defined $b && $a eq $b) ||
                     (! defined $a && ! defined $b);
               }, $a, $b);
}

my $i = 1;
sub test
{
   my ($result) = @_;

   ++$i;
   printf "%s %d\n", ($result ? "ok" : "not ok"), $i;
}

sub test_entry
{
   my ($entry, $type, $key, $fields, $values) = @_;
   my ($i, @vals);

   croak "test_entry: num fields != num values"
      unless $#$fields == $#$values;
   test ($entry->parse_ok);
   test ($entry->type eq $type);
   test (defined $key ? $entry->key eq $key : !defined $entry->key);
   test (slist_equal ([$entry->fieldlist], $fields));
   for $i (0 .. $#$fields)
   {
      my $val = $entry->get ($fields->[$i]) || '';
      test ($entry->exists ($fields->[$i]) &&
            $val eq $values->[$i]);
   }

   @vals = map ($_ || '', $entry->get (@$fields));
   test (slist_equal (\@vals, $values));
}

1;
