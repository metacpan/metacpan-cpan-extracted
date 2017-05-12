# Copyright © 2009-2013 David Caldwell and Jim Radford.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.12.4 or,
# at your option, any later version of Perl 5 you may have available.

package File::HashCache::JavaScript;
use JavaScript::Minifier::XS;
use File::HashCache;

our $VERSION = '1.0.2'; # Sadly, needs to stay here as long as File-HashCache-Javascript-0.10.0 is on CPAN.

sub new {
    my $class = shift;
    my %options = (minify => 1, @_);
    return File::HashCache->new(cache_dir => 'js',
                                process_js => [ \&File::HashCache::pound_include,
                                                $options{minify} ? \&JavaScript::Minifier::XS::minify : (), ],
                                %options);
}

1;

__END__

=head1 NAME

File::HashCache::JavaScript - Minify and cache javascript files based on the
hash of their contents.

=head1 SYNOPSIS

  use File::HashCache::JavaScript;

  my $jsh = File::HashCache::JavaScript->new();

  my $hashed_minified_path = $jsh->hash("my_javascript_file.js");
  # returns "my_javascript_file-7f4539486f2f6e65ef02fe9f98e68944.js"

  # If you are using Template::Toolkit you may want something like this:
  $template->process('template.tt2', {
      script => sub {
          my $path = $jsh->hash($_[0]);
          "<script src=\"js/$path\" type=\"text/javascript\"></script>\n";
      } } ) || die $template->error();

  # And in your template.tt2 file:
  #    [% script("myscript.js") %]
  # which will get replaced with something like:
  #    <script src="js/myscript-708b88f899939c4adedc271d9ab9ee66.js"
  #            type="text/javascript"></script>

=head1 DESCRIPTION

File::HashCache::Javascript is a thin wrapper around the more generic
L<File::HashCache> module. It remains here mostly for backwards
compatibility. It is recommended that new programs use L<File::HashCache>
directly, passing in C<< process_js => \&JavaScript::Minifier::XS::minify
>>.

=head1 SEE ALSO

L<File::HashCache>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2009 David Caldwell and Jim Radford.

=head1 AUTHOR

=over

=item *

David Caldwell <david@porkrind.org>

=item *

Jim Radford <radford@blackbean.org>

=back

=cut
