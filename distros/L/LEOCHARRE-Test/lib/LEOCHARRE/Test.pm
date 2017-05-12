package LEOCHARRE::Test;
eval { use lib './lib'; };
use strict 'vars';
use Test::Builder::Module;
use vars qw(@EXPORT @ISA $VERSION $PART_NUMBER $ABS_MYSQLD);
@EXPORT = qw(ok_part ok test_is_interactive ok_mysqld spacer mysqld_running mysqld_exists stderr_spacer);
$VERSION = sprintf "%d.%02d", q$Revision: 1.11 $ =~ /(\d+)/g;
@ISA    = qw(Test::Builder::Module);
use Carp;

$ABS_MYSQLD ||= '/etc/init.d/mysqld';

my $CLASS = __PACKAGE__;

sub ok ($;$) {
    $CLASS->builder->ok(@_);
}
sub ok_part {
   my $msg = shift;
   $msg ||='';
   my @arg= ('PART', $PART_NUMBER++, uc($msg));
   
   carp("\n\n\n======================================\n@arg, ");
   return 1;
}

sub stderr_spacer { print STDERR "\n\n" }


sub test_is_interactive { -t STDIN && -t STDOUT }

sub ok_mysqld {

   my $host = $_[0] ||= 'localhost';
   

   if ( $host eq 'localhost' and mysqld_exists() ){
      return _ok_mysqld_via_daemon();
   }

   return _ok_mysqld_via_dbi($host);
}


sub _ok_mysqld_via_daemon {   
   ok( mysqld_running(), "mysqld running on host, $ABS_MYSQLD is running")
}

sub _ok_mysqld_via_dbi {

   my $host = $_[0] ||= 'localhost';
   require DBI;
   require DBD::mysql;

   # make a bogus connect on purpose
   my $user = 'a'.time().( int rand(20) );
   my $pass = 'b'.time().( int rand(20) );
   my $name = 'c'.time().( int rand(20) );

   my $h = "DBI:mysql:database=$name;host=$host";
   
   my $dbh = DBI->connect($h, $user, $pass,{ RaiseError => 0, PrintError => 0});
   my $err = $DBI::errstr;

   my $result;

   if($err=~/Unknown MySQL server host|Can\'t connect to local MySQL server/i){
      $result = 0;;
   }
   elsif ( $err=~/Access denied for user/i ){
      $result = 1;
   }
   else {
      warn("dont know how to interpret this error: '$err'");
      $result = 0;
   }

   ok($result, "[$result] mysql host '$host' is up ? " . ($result ? 'yes' : "no. 
   Check your /etc/init.d/mysqld status or equivalent."));
}


sub mysqld_exists {
   my $path = ( $_[0] ? $_[0] : $ABS_MYSQLD ) or confess('missing ABS_MYSQLD or arg');
   -e $path ? $path : 0
}

sub mysqld_running {
   my $path = ( $_[0] ? $_[0] : $ABS_MYSQLD ) or confess('missing ABS_MYSQLD or arg');
   
   mysqld_exists($path) or warn("daemon does not exist on disk: $path\n") and return;
   my $r = `$path status`;
   $r=~/stopped/i and return 0;
   $r=~/running/i and return 1;
   warn("dunno $path status '$r'");
   return;
}




1;


__END__


=pod

=head1 NAME

LEOCHARRE::Test - personal testing subs

=head1 EXPORTED

All are exported.

=head2 ok()

Like Test::Simple

=head2 ok_part()

Optional arg is message, helps read test output.
Just a separator.

=head2 test_is_interactive()

Returns boolean. If run from a terminal, returns true, if from cpan, false.

=head2 ok_mysqld()

Argument is hostname.
Tests if a mysqld host server is up.

=head2 mysqld_running()

Returns boolean.
Optional argument is hostname.
If it is localhost, uses ABS_MYSQLD status.

=head2 mysqld_exists()

=head2 stderr_spacer()

Prints two lines to stder

=head2 $LEOCHARRE::Test::ABS_MYSQLD

Holds abs path to mysqld, default is  /etc/init.d/mysqld

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2008 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

