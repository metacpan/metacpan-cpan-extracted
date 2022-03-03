use v5.26;
use warnings;

package Mac::Finder::Tags;
# ABSTRACT: Access macOS file tags (aka Finder labels)
$Mac::Finder::Tags::VERSION = '0.01';

use Mac::PropertyList 'parse_plist';
use Object::Pad 0.43;
use Path::Tiny;

use Mac::Finder::Tags::Impl::mdls;
use Mac::Finder::Tags::Impl::xattr;
use Mac::Finder::Tags::Tag;


# to prevent an extremely long caching period
our $MAX_TRIES = 5;


class Mac::Finder::Tags :strict(params) {
	
	has $impl :param = undef;
	has $caching :param = 0;
	has $file_cache;
	has @tags_cache;
	
	ADJUST {
		$impl = $caching ? 'xattr' : 'mdls' unless defined $impl;
		$impl = "Mac::Finder::Tags::Impl::$impl"->new();
		if ($caching) {
			@tags_cache = $self->all_tags;
			$file_cache = $self->_file_cache;
		}
	}
	
	method _file_cache () {
		$file_cache = {};
		for my $tag (@tags_cache) {
			my $name = $tag->name;
			my @files = `mdfind "(kMDItemUserTags == '$name')"`;
			for my $file (@files) {
				chomp $file;
				push $file_cache->{$file}->@*, $tag;
			}
		}
		return $file_cache;
	}
	
	method tag ( $name, $color = undef ) {
		Mac::Finder::Tags::Tag->new( name => $name, color => $color );
	}
	
	method get_tags ($path) {
		return $impl->get_tags($path) unless $file_cache;
		$path = path($path)->absolute;
		my $tags = $file_cache->{$path};
		return my @empty unless $tags;
		return @$tags;
	}
	
	method set_tags ( $path, @tags ) { ... }
	method add_tags ( $path, @tags ) { ... }
	method remove_tags ( $path, @tags ) { ... }
	
	method all_tags () {
		return @tags_cache if @tags_cache;
		
		my @names = `mdfind -0 "(kMDItemUserTags == '*')" | xargs -0 mdls -name kMDItemUserTags | cut -d , -f 1 | sort -u`;
		@names = map {
			Mac::Finder::Tags::Impl::mdls::decode_cesu8
			Mac::Finder::Tags::Impl::mdls::trim
			$_
		} grep !m/ = \($|^\)$/, @names;
		my @all_tags = map {
			my $name = $_;
			my $name_esc = $name =~ s/([\\"'])/\\$1/rg;
			my $label;
			my $tries = 0;
			for my $file (`mdfind "(kMDItemUserTags == '$name_esc')"`) {
				chomp $file;
				my @file_tags = $impl->get_tags($file);
				@file_tags = grep { $_->name eq $name } @file_tags;
				next unless @file_tags == 1;
				last if defined( $label = $file_tags[0]->color );
				last if ++$tries > $MAX_TRIES;
			}
			$self->tag( $name, $label );
		} @names;
		return @all_tags;
	}
	
	method find_files_all ( @tags ) { ... }
	method find_files_any ( @tags ) { ... }
	
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mac::Finder::Tags - Access macOS file tags (aka Finder labels)

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 my $ft = Mac::Finder::Tags->new();
 
 # optional caching of all tagged files on startup
 my $ft = Mac::Finder::Tags->new( caching => 1 );
 
 # manually choose an implementation variant
 my $ft = Mac::Finder::Tags->new( impl => 'mdls' );
 my $ft = Mac::Finder::Tags->new( impl => 'xattr' );
 
 # read tags from a file
 my @tags = $ft->get_tags( $path );
 
 # obtain tag details
 my $name  = $tag->name;
 my $color = $tag->color;
 my $flags = $tag->flags;  # Finder label flags (numeric color code)
 my $emoji = $tag->emoji;  # an Emoji approximating the color
 my $is_legacy  = $tag->legacy_label;   # legacy Finder label
 my $is_guessed = $tag->color_guessed;  # color is uncertain or
                                        # undetermined (mdls only)
 
 # modify tags of a file
 my $tag1 = $ft->tag( 'Important', 'orange' );
 my $tag2 = $ft->tag( 'Client 276' );
 $ft->set_tags( $path, @tags );
 $ft->add_tags( $path, @tags );
 $ft->remove_tags( $path, @tags );
 
 # list all tags defined on the system
 my @tags = $ft->all_tags();
 
 # search entire system for files by tag
 my @files = $ft->find_files_all( @tags );
 my @files = $ft->find_files_any( @tags );

=head1 DESCRIPTION

This class offers methods to read and write macOS file system tags
(the feature that replaced Mac OS Finder labels from OS X 10.9).

It is also an attempt to put L<Object::Pad> to some use. As such,
all the warnings about the experimental status of L<Object::Pad>
apply directly to this module as well.

This software has pre-release quality. There is little documentation
and no schedule for further development.

=head1 PERFORMANCE CONSIDERATIONS

The implementation based on C<mdls> is much faster than the one
based on C<xattr>. However, C<mdls> doesn't provide the color of
tags for files that have multiple tags. This issue is mitigated
to some extent when caching is enabled.

When caching is enabled, I<all> tags on the entire system will be
cached using C<mdfind> at object creation time. C<get_tags()> will
then only perform lookups in this cache, which is extremely fast.
You should consider caching whenever you intend to look up more
than maybe a hundred or so files; however, if your system has an
extremely large number of tagged files or a large number of
different tags, cache creation may cause a significant delay. You
may wish to run your own performance tests for your environment.

By default, this module will use C<mdls> when caching is disabled,
and C<xattr> when caching is enabled (in which case the speed
difference doesn't matter as much).

=head1 BUGS

The semantics of tags without color (legacy Finder labels flag C<0>)
and tags with no I<defined> color (because it is undetermined or
unknown) are not yet clearly differentiated.

The following methods are unimplemented in this version:

=over

=item * C<add_tags>

=item * C<set_tags>

=item * C<find_files_all>

=item * C<find_files_any>

=item * C<remove_tags>

=back

This software may not work on other filesystems than HFS+ or APFS.
So far, it has only been tested on macOS 10.15.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
