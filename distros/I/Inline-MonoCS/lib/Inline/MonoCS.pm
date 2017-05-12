
package Inline::MonoCS;

use strict;
use warnings 'all';
use Digest::MD5 'md5_hex';
use Carp 'confess';

our $VERSION = '1.000';

sub import {
  my $class = shift;
  
  return unless @_;
  my %args      = @_;
  my $s         = bless \%args, $class;
  $s->{caller}  = caller;
  $s->_compile_code();
  $s->_install_method();
}


*compile = \&import;


sub _compile_code {
  my ($s) = @_;
  
  my $sig = md5_hex($s->{code});
  my $cs = "/tmp/$s->{method}_$sig.cs";
  $s->{exe} = "/tmp/$s->{method}_$sig.exe";
  my $compiler =  `which gmcs`;
  chomp($compiler);
  $compiler ||= 'gmcs';
  my $cmd_line = "$compiler -out:$s->{exe} $s->{compiler_args} $cs";
  
  unless( -f $s->{exe} )
  {
    open my $ofh, '>', $cs
      or confess "Cannot open '$cs' for writing: $!";
    print $ofh $s->{code};
    close($ofh);
    
    my $errors = `$cmd_line`;
    confess "Error compiling '$cs': $errors" if $errors;
    unlink($cs);
  }# end unless()
}


sub _install_method {
  my $s = shift;
  
  no strict 'refs';
  *{"$s->{caller}::$s->{method}"} = sub {
    my @args = map { qq("$_") } @_;
    my $res = `mono $s->{exe} @args`;
    chomp($res);
    return $res;
  };
}


1;# return true:

=pod

=head1 NAME

Inline::MonoCS - Use CSharp from Perl, via Mono

=head1 SYNOPSIS

=head2 Hello World

  use Inline::MonoCS
    method        => "HelloWorld",
    compiler_args => "",
    code          => <<"CODE";
  public class HelloWorld
  {
      public static void Main( string[] args)
      {
          System.Console.WriteLine( "Hello, " + args[0] + "!" );
      }
  }
  CODE

  warn HelloWorld("Frank"); # "Hello, Frank!"

=head2 Talk to Microsoft SQL Server from Linux

  use Inline::MonoCS
    method        => "ProductCount",
    compiler_args => "-r:System.Data.dll",
    code          => <<'CODE';
  using System;
  using System.Data;
  using System.Data.SqlClient;

  public class ProductCount
  {
      public static void Main(string[] args)
      {
         string connectionString =
            "Server=111.222.111.222;" +
            "Database=northwind;" +
            "User ID=sa;" +
            "Password=s3cr3t;";
         IDbConnection dbcon;
         using (dbcon = new SqlConnection(connectionString)) {
             dbcon.Open();
             using (IDbCommand dbcmd = dbcon.CreateCommand()) {
                 string sql =
                     "SELECT COUNT(*) AS ProductCount " +
                     "FROM Products";
                 dbcmd.CommandText = sql;
                 using (IDataReader reader = dbcmd.ExecuteReader()) {
                     while(reader.Read()) {
                         int ProdCount = Convert.ToInt32( reader["ProdCount"] );
                         Console.WriteLine( ProdCount );
                     }
                 }
             }
         }
      }
  }
  CODE

  my $count = ProductCount();
  warn "We have $count products";

=head1 DESCRIPTION

This module provides a simple bridge to execute code written in C# from Perl.

It works by compiling your code, then placing the executable under /tmp/ and 
exporting a subroutine into the calling package.  When you call that exported
subroutine, the compiled exe is executed and given your arguments on the command-line.

Whatever your program outputs to STDOUT is considered the return value.

=head1 AUTHOR

Written by John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is Free software and may be used and redistributed under the same terms as perl itself.

=cut

