##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/FileList.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/25
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::FileList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Array );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub item { return( shift->index( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::FileList - HTML Object DOM FileList Class

=head1 SYNOPSIS

    use HTML::Object::DOM::FileList;
    my $list = HTML::Object::DOM::FileList->new || 
        die( HTML::Object::DOM::FileList->error, "\n" );

    <input id="fileItem" type="file" />
    my $file = $doc->getElementById('fileItem')->files->[0];

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

An object of this type is returned by the L<HTML::Object::DOM::Element::Input/files> property of the HTML C<<input>> element; this lets you access a list of files you would have set or added, removed, etc.. It inherits from L<Module::Generic::Array>

Normally, under JavaScript, those files are selected with the C<<input type="file" />> element. It is also used on the web for a list of files dropped into web content when using the drag and drop API; see the L<DataTransfer object on Mozilla|https://developer.mozilla.org/en-US/docs/Web/API/DataTransfer> for details on this usage.

=head1 PROPERTIES

=head2 length

Read-only.

Returns the number of files in the list.

=head1 METHODS

=head2 item

Returns a L<HTML::Object::DOM::File> object representing the file at the specified index in the file list.

Example:

    # fileInput is an HTML input element: <input type="file" id="myfileinput" multiple />
    my $fileInput = $doc->getElementById("myfileinput");

    # files is a FileList object (similar to NodeList)
    my $files = $fileInput->files;
    my $file;

    # loop through files
    for( my $i = 0; $i < $files->length; $i++ )
    {
        # get item
        $file = $files->item($i);
        # or
        $file = $files->[$i];
        say( $file->name );
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/FileList>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
