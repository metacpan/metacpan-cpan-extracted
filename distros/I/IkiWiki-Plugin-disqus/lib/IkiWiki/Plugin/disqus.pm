package IkiWiki::Plugin::disqus;
use warnings;
use strict;

use IkiWiki 3.00;

our $VERSION = '0.01';

sub import {
    # template hook
    hook( type => 'pagetemplate', id => 'disqus', call => \&disqus_comments );
}

# Template params:
#  DISQUS_COMMENTS  : full discus comments
#  DISQUS_COUNT     : count link
sub disqus_comments {
    my %args = @_;

    $args{template}->param('DISQUS' => 1);

    # Only place the disqus code on the blog page itself.  This means
    # that the disqus code will not appear when a post is embedded in
    # the index or tag pages.
    if ($args{page} eq $args{destpage}) {
	my $shortname  = $config{'disqus_shortname'};
	my $identifier = $args{destpage};
	my $url         = urlto($args{destpage}, 'index', '1');

	foreach my $pattern (@{ $config{disqus_skip_patterns } }) {
	    if ($identifier =~ $pattern) {
		return '';
	    }
	}

	my $jscript =<<DISQUSCOMMENTS;
<div id="disqus_thread"></div>
<script type="text/javascript">
    var disqus_shortname = '$shortname'; // required: replace example with your forum shortname
    var discus_identifier = '$identifier';
    var disqus_url = '$url';

    (function() {
        var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
        dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
    })();
</script>
<noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
<a href="http://disqus.com" class="dsq-brlink">blog comments powered by <span class="logo-disqus">Disqus</span></a>
DISQUSCOMMENTS

	$args{template}->param('DISQUS_COMMENTS' => $jscript)
    }
    else {
	# this is not the page but an embedded page.
    }
}

1;

__END__

=head1 NAME

IkiWiki::Plugin::disqus - Add Disqus comments to IkiWiki pages

=head1 DESCRIPTION

This plugin makes it easy for you to add Disqus comments to pages
and blog posts in IkiWiki. It also provides a way to allow you
to prevent comments from being posted on certain pages.

=head1 INSTALLATION

Put F<disqus.pm> in F<$HOME/.ikiwiki/IkiWiki/Plugin/> or elsewhere in
your C<@INC> path.

=head1 CONFIGURATION

Add to the configuration in your F<blog.setup> file.

	## Disqus plugin
	# Your disqus forum "shortname"
	disqus_shortname => 'your_short_name',
	# A list of regular expressions matching pages that should
	# not have the disqus comments placed on them.
	#
	# Example:
	#  disqus_skip_patterns => [ qr(^index$), qr(^posts$), qr(^tags/) ],
	disqus_skip_patterns => [ qr(^index$), qr(^posts$), qr(^tags/) ],

Add C<disqus> to the list of plugins:

        add_plugins => [qw{goodstuff disqus}],

You should also turn off the comments plugin"

        disable_plugins => [qw(comments)],

=head1 TEMPLATES

You will need to add the following code to F<page.tmpl>. I suggest putting
it just before the C<COMMENTS> block or after the C<content> div.

 <TMPL_IF DISQUS>
 <div id="disqus_comments">
 <TMPL_VAR DISQUS_COMMENTS>
 </div>
 </TMPL_IF>

=head1 BUGS AND LIMITATIONS

Report bugs at http://code.google.com/p/ikiwiki-plugin-disqus/issues/list

=head1 AUTHOR(S)

Randall Smith <perlstalker@vuser.org>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012  Randall Smith

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=head1 SEE ALSO

=over 4

=item http://ikiwiki.info/

=item http://docs.disqus.com/developers/universal/

=back
