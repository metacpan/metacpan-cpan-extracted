package File::Find::Rule::Digest;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use Digest;
use FileHandle;
use File::Find::Rule;
use base qw(File::Find::Rule);

use vars qw(@EXPORT);
@EXPORT = @File::Find::Rule::EXPORT;

sub File::Find::Rule::md2  { _match_digest(shift, "MD2"   => shift)  }
sub File::Find::Rule::md5  { _match_digest(shift, "MD5"   => shift)  }
sub File::Find::Rule::sha1 { _match_digest(shift, "SHA-1" => shift)  }
sub File::Find::Rule::hmac { _match_digest(shift, "HMAC"  => shift)  }

sub _match_digest {
    my $self = shift->_force_object();
    my($imp, $checksum) = @_;
    $self->exec(
	sub {
	    my $file = shift;
	    my $digest = Digest->new($imp);
	    $digest->addfile(FileHandle->new($file));
	    $digest->hexdigest eq $checksum;
	},
    );
}


1;
__END__

=head1 NAME

File::Find::Rule::Digest - rules for matchig checksum

=head1 SYNOPSIS

  use File::Find::Rule::Digest;

  # find files to match some digest
  @files = find(file => md5 => 'a11d9dfbb277c90efe4c2d440feb47ba', in => '/var' );

  # OO
  @files = File::Find::Rule::Digest->file()
                                   ->sha1('88f008ad809bd3635b412ce2197d5bec')
                                   ->in('.');

=head1 DESCRIPTION

File::Find::Rule::Digest allows you to find files based on its checksums.

=head1 METHODS

Following methods are added to File::Find::Rule.

=over 4

=item md5, sha1, hmac, md2

Finds files based on its checksum value. It uses Digest.pm module
internally to get checksum for files.

=back	  	  

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Rule>, L<Digest>

=cut
