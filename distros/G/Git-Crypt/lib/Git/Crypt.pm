package Git::Crypt;
use strict;
use warnings;
use Moo;
use IO::All;
use Crypt::CBC;
use MIME::Base64;
use Crypt::Blowfish;

has files       => ( is => 'rw', default => sub { [] } );
has salt        => ( is => 'rw', default => sub { 0 } );
has key         => ( is => 'rw', default => sub { 0 } );
has cipher_name => ( is => 'rw', default => sub { 'Blowfish' } );
has cipher      => (
    is      => "lazy",
    default => sub {
        my $self = shift;
        Crypt::CBC->new(
            -key    => $self->key,
            -cipher => $self->cipher_name,
            -salt   => pack( "H16", $self->salt )
        );
    }
);

sub encrypt {
    my $self = shift;
    my $filename = shift;
    if ( $filename ) {
        my $file = $self->locate( $filename );
        if ( ! $file ) {
            print "File $filename not found. Use 'gitcrypt status' to check files added.\n";
            return;
        }
        if ( $file->{ is_encrypted } ) {
            print "File $filename is already encrypted.\n";
            return;
        }
        $self->encrypt_file( $file );
    } else {
        for ( @{ $self->files } ) {
            next if $_->{is_encrypted};
            $self->encrypt_file( $_ );
        }
    }
}

sub encrypt_file {
    my $self = shift;
    my $file = shift;
    my @lines_crypted =
      map { encode_base64( $self->cipher->encrypt($_), "" )."\n"; } io($file->{file})->getlines;
    io($file->{file})->print(@lines_crypted);
    $file->{is_encrypted} = 1;
}

sub decrypt_file {
    my $self = shift;
    my $file = shift;
    return if ! $file->{is_encrypted};
    my @lines_decrypted = map {
        my $line = decode_base64 $_;
        $self->cipher->decrypt($line);
    } io($file->{file})->getlines;
    io($file->{file})->print(@lines_decrypted);
    $file->{is_encrypted} = 0;
}

sub locate {
    my $self = shift;
    my $filename = shift;
    my $file_found;
    map { ( $_->{file} eq $filename ) ? ( $file_found = $_ ) : () } @{ $self->files };
    return $file_found;
}

sub decrypt {
    my $self = shift;
    my $filename = shift;
    if ( $filename ) {
        my $file = $self->locate( $filename );
        if ( ! $file ) {
            print "File $filename not found. Use 'gitcrypt status' to check files added.\n";
            return;
        }
        if ( ! $file->{ is_encrypted } ) {
            print "File $filename is already decrypted.\n";
            return;
        }
        $self->decrypt_file( $file );
    } else {
        for ( @{ $self->files } ) {
            my $file = $_;
            next if ! $file->{is_encrypted};
            $self->decrypt_file( $file );
        }
    }
}

sub add {
    my $self = shift;
    my $files = shift;
    my @current_files = map { $_->{ file } } @{ $self->files };
    map {
        print $_, "\n";
        my $file = $_;
        push @{ $self->files }, {file => $file, is_encrypted => 0 }
            if ! grep /^$file$/, @current_files;
    } @{$files};
}

sub del {
    my $self = shift;
    my $files = shift;
    map {
        my $file_to_del = $_;
        print $file_to_del, "\n";
        my $i = 0;
        for ( @{ $self->files } ) {
            if ( $_->{ file } eq $file_to_del ) {
                splice @{ $self->files }, $i, 1;
                last;
            }
            $i++;
        }
    } @{$files};
}

sub config {
    my $self = shift;
    return {
        files   => $self->files,
        cipher_name  => $self->cipher_name,
        key     => $self->key,
        salt    => $self->salt,
    };
}

our $VERSION = 0.05;

=encoding utf8

=head1 Git::Crypt

Git::Crypt - Encrypt/decrypt sensitive files saved on public repos

=head1 SYNOPSIS

=head2 gitcrypt Command line tool
    
 gitcrypt help                    #show gitcrypt help
 gitcrypt init                    #initialize gitcrypt and its config
 gitcrypt set cipher Blowfish     #set a gitcrypt cipher
 gitcrypt set key   "some key"    #set a key
 gitcrypt set salt  "some key"    #set a salt
 gitcrypt change key "new key"    #change key
 gitcrypt change salt "a salt"    #change salt
 gitcrypt list                    #list files
 gitcrypt status                  #show status, files
 gitcrypt add file1-xy lib/file2  #add files in gitcrypt
 gitcrypt del file1-ab lib/tests  #del files in gitcrypt
 gitcrypt encrypt                 #set files on encrypted state
 gitcrypt encrypt file1 file2     #encrypt specific files
 gitcrypt decrypt                 #set files on decrypted state
 gitcrypt decrypt file1 file2     #decrypt specific files
 gitcrypt precommit               #encrypt for precommit hook. Then decrypt

=head2 git hooks integration

To integrate in git, use git hooks. Use pre-commit to encrypt and add the encrypted file for commit. And post-commit to keep files decrypted.

=head3 Standard git hooks

=head4 .git/hooks/pre-commit

Auto encrypt every file and set them for commit

 $ file=.git/hooks/pre-commit ; cat <<HOOK > $file && chmod +x $file
 #!/usr/bin/env perl
 `gitcrypt precommit`;
 exit 0;
 HOOK

If used gitcrypt precommit the files will be encrypted during commit and decrypted right after.

This mode works good if only some files are encrypted and others are always decrypted. But all must be encrypted for commit.

Another option, is to encrypt everything with "gitcrypt encrypt". And use a post-commit hook to decrypt everything [optional].

 $ file=.git/hooks/pre-commit ; cat <<HOOK > $file && chmod +x $file
 #!/usr/bin/env perl
 `gitcrypt encrypt`;
 exit 0;
 HOOK

=head4 .git/hooks/post-commit

Auto decrypt every file after commit executed. * If precommit hook uses gitcrypt precommit, then this is not necessary because "gitcrypt precommit" will decrypt files automatically. 

 $ file=.git/hooks/post-commit; cat <<HOOK > $file ; chmod +x $file
 #!/usr/bin/env perl
 `gitcrypt decrypt`;
 exit 0;
 HOOK

=head2 Provide the cipher instance

  my $gitcrypt = Git::Crypt->new(
      files => [
          {
              file => 'file1',
              is_encrypted => 0,
          },
          {
              file => 'file2',
              is_encrypted => 0,
          },
      ],
      cipher => Crypt::CBC->new(
          -key      => 'a very very very veeeeery very long key',
          -cipher   => 'Blowfish',
          -salt     => pack("H16", "very very very very loooong salt")
      )
  );

  #gitcrypt->add([qw| file1 file2 |]);
  #gitcrypt->del([qw| file1 file2 |]);
  #gitcrypt->list;
  #gitcrypt->key('some key');
  #gitcrypt->salt('some key');
  $gitcrypt->crypt;     #save files encrypted
  $gitcrypt->decrypt;   #save files decrypted

=head2 Provide key, salt and cipher name

  my $gitcrypt = Git::Crypt->new(
      files => [
          {
              file => 'file1',
              is_encrypted => 0,
          },
          {
              file => 'file2',
              is_encrypted => 0,
          },
      ],
      key         => 'a very very very veeeeery very long key',
      cipher_name => 'Blowfish',
      salt        => pack("H16", "very very very very loooong salt")
  );

  #gitcrypt->add([qw| file1 file2 |]);
  #gitcrypt->del([qw| file1 file2 |]);
  #gitcrypt->list;
  #gitcrypt->key('some key');
  #gitcrypt->salt('some key');
  $gitcrypt->crypt;     #save files encrypted
  $gitcrypt->decrypt;   #save files decrypted

=head1 DESCRIPTION

Git::Crypt can be used to encrypt files before a git commit. That way its possible to upload encrypted files to public repositories.
Git::Crypt encrypts line by line to prevent too many unnecessary diffs between encrypted commits.

=head1 Diff on encrypted lines

Since gitcrypt encrypts line by line, the diff can show wether its a big/small changes in commit.

 index b1202fc..6c2f3e6 100644
 --- a/lib/App/Crypted/CreditCard.pm
 +++ b/lib/App/Crypted/CreditCard.pm
 @@ -14,25 +14,29 @@ U2FsdGVkX19iyl3d3d3d3UjtB1nkCoDP
  U2FsdGVkX19iyl3d3d3d3T3HmAPM6gbK
  U2FsdGVkX19iyl3d3d3d3XVxkdxldN7U
  U2FsdGVkX19iyl3d3d3d3X49YqpLm/iZ+Y1xf1iU/BDvVc5ipe6ZgQ==
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 -U2FsdGVkX19iyl3d3d3d3Ut9C6nKtOzc
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
 +U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxgEmpWYlLzsk=
  U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rx2ego3EqSeUk=
  U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxsn4D6bxrGww=
  U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rxsn4D6bxrGww=
  U2FsdGVkX19iyl3d3d3d3Tz+ZxmSz/rx2ego3EqSeUk=
  U2FsdGVkX19iyl3d3d3d3T3HmAPM6gbK
  U2FsdGVkX19iyl3d3d3d3XVxkdxldN7U
 +U2FsdGVkX19iyl3d3d3d3T0XLptL7y1QEx/u7OaQVy2BZbX3SM7f2w==
 +U2FsdGVkX19iyl3d3d3d3erugupayFMCneYosuHZNbl3jV0GvJ1HDg==
 +U2FsdGVkX19iyl3d3d3d3T3HmAPM6gbK
 +U2FsdGVkX19iyl3d3d3d3XVxkdxldN7U
  U2FsdGVkX19iyl3d3d3d3X/cRzzeMPXS

=head1 AUTHOR

 Hernan Lopes
 CPAN ID: HERNAN
 perldelux
 hernanlopes@gmail.com

=head1 GITHUB

 https://github.com/hernan604/Git-Crypt

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;

# The preceding line will help the module return a true value

