package MPMinus::MainTools::MD5; # $Id: MD5.pm 122 2013-05-07 13:05:41Z minus $
use strict;

=head1 NAME

MPMinus::MainTools::MD5 - MD5 functions

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use MPMinus::MainTools::MD5;

    my $md5_apache = get_md5_apache( $password );
    my $md5_unix = get_md5_unix( $password );

=head1 DESCRIPTION

MD5 functions

=over 8

=item B<get_md5_apache>

    my $md5_apache = get_md5_apache( $password );

=item B<get_md5_unix>

    my $md5_unix = get_md5_unix( $password );

=back

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw($VERSION);
$VERSION = 1.01;

use base qw/Exporter/;
our @EXPORT = qw(
        get_md5_apache get_md5_unix
    );

use Digest::MD5;

my $Magic;
my $itoa64 = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

sub get_md5_apache {
    my $password = shift || return 0;
    return apache_md5_crypt($password,&get_salt);
}
sub get_md5_unix {
    my $password = shift || return 0;
    return unix_md5_crypt($password,&get_salt);
}
sub get_salt {
    my($salt,$i, $rand);
    $rand=0;
    my (@itoa64) = (0 .. 9,'a' .. 'z','A' .. 'Z'); 
    $salt = '';
    for ($i = 0; $i < 8; $i++) {
      srand(time + $rand + $$);
      $rand = rand(25*29*17 + $rand);
      $salt .=  $itoa64[$rand & $#itoa64];
    }
    return $salt; # crypt($passwd,$salt);
}
sub to64 {
    my ($v, $n) = @_;
    my $ret = '';
    while (--$n >= 0) {
        $ret .= substr($itoa64, $v & 0x3f, 1);
        $v >>= 6;
    }
    return $ret;
}
sub apache_md5_crypt {
    $Magic = q/$apr1$/;
    return _md5_crypt(@_);
}
sub unix_md5_crypt {
    $Magic = q/$1$/;
    return _md5_crypt(@_);
}
sub _md5_crypt {
    my($pw, $salt) = @_;
    my $passwd;

    if ( defined $salt ) {
        $salt =~ s/^\Q$Magic//; # Take care of the magic string if
                                # if present.
        $salt =~ s/^(.*)\$.*$/$1/; # Salt can have up to 8 chars...
        $salt = substr($salt, 0, 8);
    } else {
        $salt = ''; # in case no salt was proffered
        $salt .= substr($itoa64,int(rand(64)+1),1)
            while length($salt) < 8;
    }

    my $ctx = new Digest::MD5; # Here we start the calculation
    $ctx->add($pw); # Original password...
    $ctx->add($Magic); # ...our magic string...
    $ctx->add($salt); # ...the salt...

    my ($final) = new Digest::MD5;
    $final->add($pw);
    $final->add($salt);
    $final->add($pw);
    $final = $final->digest;

    my $pl;
    for ($pl = length($pw); $pl > 0; $pl -= 16) {
        $ctx->add(substr($final, 0, $pl > 16 ? 16 : $pl));
    }

    # Now the 'weird' xform
    my $i;
    for ($i = length($pw); $i; $i >>= 1) {
        if ($i & 1) { $ctx->add(pack("C", 0)); }
        # This comes from the original version,
        # where a memset() is done to $final
        # before this loop.
        else { $ctx->add(substr($pw, 0, 1)); }
    }
    $final = $ctx->digest;

    # The following is supposed to make
    # things run slower. In perl, perhaps
    # it'll be *really* slow!
    my $ctx1;
    for ($i = 0; $i < 1000; $i++) {
        $ctx1 = new Digest::MD5;
        if ($i & 1) { $ctx1->add($pw); }
        else { $ctx1->add(substr($final, 0, 16)); }
        if ($i % 3) { $ctx1->add($salt); }
        if ($i % 7) { $ctx1->add($pw); }
        if ($i & 1) { $ctx1->add(substr($final, 0, 16)); }
        else { $ctx1->add($pw); }
        $final = $ctx1->digest;
    }
    
    # Final xform
    $passwd = '';
    $passwd .= to64(int(unpack("C", (substr($final, 0, 1))) << 16)
            | int(unpack("C", (substr($final, 6, 1))) << 8)
            | int(unpack("C", (substr($final, 12, 1)))), 4);
    $passwd .= to64(int(unpack("C", (substr($final, 1, 1))) << 16)
            | int(unpack("C", (substr($final, 7, 1))) << 8)
            | int(unpack("C", (substr($final, 13, 1)))), 4);
    $passwd .= to64(int(unpack("C", (substr($final, 2, 1))) << 16)
            | int(unpack("C", (substr($final, 8, 1))) << 8)
            | int(unpack("C", (substr($final, 14, 1)))), 4);
    $passwd .= to64(int(unpack("C", (substr($final, 3, 1))) << 16)
            | int(unpack("C", (substr($final, 9, 1))) << 8)
            | int(unpack("C", (substr($final, 15, 1)))), 4);
    $passwd .= to64(int(unpack("C", (substr($final, 4, 1))) << 16)
            | int(unpack("C", (substr($final, 10, 1))) << 8)
            | int(unpack("C", (substr($final, 5, 1)))), 4);
    $passwd .= to64(int(unpack("C", substr($final, 11, 1))), 2);

    $final = '';
    return $Magic . $salt . q/$/ . $passwd;
}

1;

__END__

  my $usr_name=lc('admin');
  my $usr_password=lc('password');
  my $apachepassword = apache_md5_crypt($usr_password,&get_salt);

  open PASS, $password_file_path;
   flock PASS,2;
   @temp=<PASS>;
  close PASS;
  
  open PASS, ">".$password_file_path;
   flock PASS,2;
   foreach my $a(@temp){
      $a=~/^(.+?)\:/;
      $temp_3=$1;
      print PASS $a if ($usr_name ne $temp_3);
   }
   print PASS ($usr_name.':'.$apachepassword."\n") if (($usr_action eq 'update') or ($temp_3 eq $minus_user));
  close PASS;
