package Gimp::Data;

use strict;
use warnings;
use POSIX qw(locale_h);

sub freeze($) {
   my $data = shift;
   return $data unless ref $data or _looks_frozen($data);
   my $locale = setlocale(LC_NUMERIC); setlocale(LC_NUMERIC, "C");
   require Data::Dumper;
   $data = Data::Dumper->new([$data]);
   $data->Purity(1)->Terse(0);
   my $frozen = $data->Dump;
   setlocale(LC_NUMERIC, $locale);
   return $frozen;
}

sub _looks_frozen { shift =~ /^\$VAR1 =/; }

sub thaw {
   my $data = shift;
   if (_looks_frozen($data)) {
      my $VAR1;
      no warnings;
      return eval $data;
   }
   $data;
}

sub TIEHASH {
   my $pkg = shift;
   my $self;
   bless \$self, $pkg;
}

sub FETCH {
   my $p = eval { Gimp->get_parasite($_[1]) };
   return if $@;
   thaw($p->data);
}

sub STORE {
   my $data = freeze($_[2]);
   Gimp->attach_parasite ([$_[1], Gimp::PARASITE_PERSISTENT, $data]);
}

sub EXISTS {
   FETCH(@_) ? 1 : ();
}

my @allkeys;
my $key_index;
sub FIRSTKEY {
   @allkeys = Gimp->get_parasite_list;
   $key_index = 0;
   $allkeys[$key_index];
}

sub NEXTKEY {
   die "NEXTKEY: expected last key $allkeys[$key_index] but got $_[1]\n"
      unless $allkeys[$key_index] eq $_[1];
   $allkeys[++$key_index];
}

sub DELETE {
   my $value = FETCH(@_);
   Gimp->detach_parasite($_[1]);
   $value;
}

tie %Gimp::Data, __PACKAGE__;

1;
__END__

=head1 NAME

Gimp::Data - Set and get persistent data.

=head1 SYNOPSIS

  use Gimp::Data;

  $Gimp::Data{'value1'} = "Hello";
  print $Gimp::Data{'value1'},", World!!\n";

=head1 DESCRIPTION

With this module, you can access plugin-specific (or global) data in Gimp,
i.e. you can store and retrieve values that are stored in the main Gimp
application.

An example would be to save parameter values in Gimp, so that on subsequent
invocations of your plug-in, the user does not have to set all parameter
values again (L<Gimp::Fu> does this already).

=head1 %Gimp::Data

You can store and retrieve anything you like in this hash. Its contents
will automatically be stored in Gimp, and can be accessed in later
invocations of your plug-in. Be aware that other plug-ins store data
in the same "hash", so better prefix your key with something unique,
like your plug-in's name. As an example, the Gimp::Fu module uses
"function_name/_fu_data" to store its data.

As of L<Gimp> version 2.3 (and GIMP 2.8), your data B<will> survive a
restart of the Gimp application.

C<Gimp::Data> will freeze your data when you pass in a reference. On
retrieval, the data is thawed again. See L<Data::Dumper> for more info.

=head1 AUTHOR

Marc Lehmann <pcg@goof.com>

=head1 SEE ALSO

perl(1), L<Gimp>.
