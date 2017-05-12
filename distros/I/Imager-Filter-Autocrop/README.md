# Imager::Filter::Autocrop - Automatic crop filter for Imager.

This module extends Imager functionality with the autocrop filter, similar to
ImageMagick and GraphicsMagick "trim". It does have a few additional features
as well, such as support for the border or detection-only mode. The command-line
script autocrop.pl is also provided.

### COMPATIBILITY

The module should run fine on both Lunux and Windows platforms (under ActiveState Perl
and Strawberry Perl) with Imager versions 0.91 and up.

### INSTALLATION

**With CPANminus**

    cpanm Imager::Filter::Autocrop
    
**With CPAN**

    cpan -i Imager::Filter::Autocrop
    
**Manual installation**:

	perl Makefile.PL
	make
	make test
	make install

### USAGE

```perl
 use Imager;
 use Imager::Filter::Autocrop;

 my $img = Imager->new();
 $img->read(file => 'image.jpg');
 $img->filter(type => 'autocrop') or die $img->errstr;
```

### NAME OVERRIDE

You can change the name under which the filter is registered, by specifying it in 'use' directive.
For example, to change the name to 'trim' from the default 'autocrop':

```perl
 use Imager;
 use Imager::Filter::Autocrop 'trim';

 $img->filter(type => 'trim') or die $img->errstr;
```

### PARAMETERS

Additional parameters to use in 'filter' call:

| Name          | Type | Default | Usage  |
| ------------- |:-------------:|:-------------:| -----|
| color     | Str/Obj | - | By default the color of the top left pixel is used for cropping. You can explicitly specify one though, by either providing the '#RRGGBB' value or passing an object of 'Imager::Color' class or its subclass. |
| fuzz      | Int     | 0 | You can specify the deviation for the color value (for all RGB channels or the main channel if it is a greyscale image), by using the 'fuzz' parameter. All image colors within the range would be treated as matching candidates for cropping. |
| border    | Int     | 0 | You can specify the border around the image for cropping. If the cropping area with the border is identical to the original image height and width, then no actual cropping will be done. |
| detect    | HashRef | - | Finally, you can just detect the cropping area by passing a hash reference as a 'detect' parameter. On success, your hash will be set with 'left', 'right', 'top' and 'bottom' keys and appropriate values. Please note that if the 'border' parameter is used, the detected area values will be adjusted appropriately. |

**Note:** If the image looks blank (whether genuinely or because of the 'fuzz' parameter), or if there is nothing to crop, then the filter call will
return false and the 'errstr' method will return appropriate message.

### SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Imager::Filter::Autocrop

You can also look for information at:

 * [RT, CPAN's request tracker (report bugs here)](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Imager-Filter-Autocrop)
 * [AnnoCPAN, Annotated CPAN documentation](http://annocpan.org/dist/Imager-Filter-Autocrop)
 
For feedback or custom development requests see:

 * Company homepage - https://do-know.com
 
### LICENSE AND COPYRIGHT

Copyright (C) 2016 Alexander Yezhov

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
