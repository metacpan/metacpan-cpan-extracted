	use HTML::Microformats;
	use LWP::Simple qw[get];
	
	my $page     = 'http://tantek.com/';
	my @xfn_objs = HTML::Microformats
	               ->new_document(get($page), $page)
	               ->assume_all_profiles
	               ->parse_microformats
	               ->objects('XFN');
	
	while (my $xfn = shift @xfn_objs)
	{
		printf("%s <%s>\n",
			$xfn->data->{title},
			$xfn->data->{href},
			);
	}
