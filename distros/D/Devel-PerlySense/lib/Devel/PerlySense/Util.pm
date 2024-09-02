=head1 NAME

Devel::PerlySense::Util - Utility routines

=cut



use strict;
use warnings;
use utf8;

package Devel::PerlySense::Util;
$Devel::PerlySense::Util::VERSION = '0.0223';
use base "Exporter";

our @EXPORT = (
    qw/
       slurp
       spew
       textRenderTemplate
       filePathNormalize
       /);





use Carp;
use Data::Dumper;
use File::Basename;
use Path::Class 0.11;
use File::Spec::Functions qw/ splitdir /;





=head1 ROUTINES

=head2 aNamedArg($raParam, @aArg)

Return list of argument valies in $rhArg for the param names in
$raParam.

Die on missing arguments.

=cut
sub aNamedArg {
	my ($raParam, @aArg) = @_;
    my %hArg = @aArg;

    my @aResult;
    for my $param (@$raParam) {
        exists $hArg{$param} or do {
            local $Carp::CarpLevel = 1;
            croak("Missing argument ($param). Arguments: (" . join(", ", sort keys %hArg) . ")");
        };
        push(@aResult, $hArg{$param});
    }

    return(@aResult);
}





=head2 slurp($file)

Read the contents of $file and return it, or undef if the file
couldn't be opened.

=cut
sub slurp {
	my ($file) = @_;
    open(my $fh, "<", $file) or return undef;
    local $/;
    return <$fh>;
}





=head2 spew($file, $text)

Crete a new $file a and print $text to it.

Return 1 on success, else 0.

=cut
sub spew {
	my ($file, $text) = @_;
    open(my $fh, ">", $file) or return 0;
    print $fh $text or return 0;
    return 1;
}





=head2 filePathNormalize($file)

Return the normalized path of $file, i.e. with "dir/dir2/../dir3"
becoming "dir/dir3".

The path doesn't have to exist.

=cut
sub filePathNormalize {
	my ($filePath) = @_;

    my @aDirNew;
    for my $dir (splitdir($filePath)) {
        if($dir eq "..") {
            ###TODO: @aDirNew or die("Malformed file ($filePath). Too many parent dirs ('sample_dir/../..')\n");
            pop(@aDirNew);
        }
        else {
            push(@aDirNew, $dir);
        }
    }
    
    return file(@aDirNew) . "";
}





=head2 textRenderTemplate($template, $rhParam)

Replace the keys in $rhParam with the values in $rhParam, for
everything in $template that looks like

  ${KEY_NAME}

Return the rendered template.

=cut
sub textRenderTemplate {
    my ($template, $rhParam) = @_;

    my $rex = join("|", map { quotemeta } sort keys %$rhParam);
    my $rhParamEnv = { %ENV, %$rhParam };

    $template =~ s/\$\{($rex)\}/ $rhParamEnv->{$1} || "" /eg;  ###TODO: should be //

    return $template;
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
