package HTTP::Server::EV::MultipartFile;
use strict;
our $VERSION = '0.69';

=head1 NAME

HTTP::Server::EV::MultipartFile - represents file received by L<HTTP::Server::EV>

=cut


sub size {$_[0]->{size}};
sub name {$_[0]->{name}};
sub path {$_[0]->{path}};


=head1 FILE PARAMETERS

=over

=item $file->size or $file->{size} 

Filesize in bytes

=item $file->name or $file->{name}

Filename received in http request

=back

=head1 METHODS

=head2 $file->fh ( sub { $handle = $_[0] or die 'can`t open file' });

Returns filehandle opened to reading. 
Callback is optional 

=head2 $file->save($path, sub { $_[0] or die 'save failed' }  );

Save received file to $path. Just moves file from tmp dir to $path if possible. 
Callback is optional 


=head1 MultipartFile IMPLEMENTATIONS, BLOCKING AND CALLBACKS 

If callback is specified it will always called after IO completion no matter what HTTP::Server::IO implementation used.

If you use L<HTTP::Server::EV::IO::AIO> then only way to know ->save status is specify callback, because ->save call will return immediately and set saving to background. You can`t use ->fh without callback.

If you use L<HTTP::Server::EV::IO::Blocking> then all IO operations will block program. You can use methods withouth a callbacks.

If you use L<Coro> then HTTP::Server::EV::IO::AIO will act as HTTP::Server::EV::IO::Blocking and block current Coro thread if no callback specified, or return immediately and call callback if callback specified.

=cut



1;