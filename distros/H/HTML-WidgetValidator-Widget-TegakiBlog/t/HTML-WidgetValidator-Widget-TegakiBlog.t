use Test::More 'no_plan';
BEGIN { use_ok('HTML::WidgetValidator') };

#########################

{
	my $validator = HTML::WidgetValidator->new(widgets => ['TegakiBlog']);
	{
		# good case for code with ads
		my $html = q{<script type="text/javascript" src="http://pipa.jp/tegaki/js/tag.js"></script>};
		ok(ref $validator, 'ref');
		ok($validator->isa('HTML::WidgetValidator'), 'isa');
			my $result = $validator->validate($html);
		ok(defined $result, 'defined');
		ok(ref($result) eq 'HTML::WidgetValidator::Result', 'ref '.ref($result));
		is($result->code, $html, 'code');
		is($result->name, 'TegakiBlog', 'name');
	}
	{
		# good case for code non ads
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=0" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=0"></embed></object>};
		ok(ref $validator, 'ref');
		ok($validator->isa('HTML::WidgetValidator'), 'isa');
			my $result = $validator->validate($html);
		ok(defined $result, 'defined');
		ok(ref($result) eq 'HTML::WidgetValidator::Result', 'ref '.ref($result));
		# is($result->code, $html, 'code');
		is($result->name, 'TegakiBlog', 'name');
	}
	{
		# good case for code with ads and ID
		my $html = q{<script type="text/javascript" src="http://pipa.jp/tegaki/js/tag.js#userID=81998"></script>};
		ok(ref $validator, 'ref');
		ok($validator->isa('HTML::WidgetValidator'), 'isa');
			my $result = $validator->validate($html);
		ok(defined $result, 'defined');
		ok(ref($result) eq 'HTML::WidgetValidator::Result', 'ref '.ref($result));
		is($result->code, $html, 'code');
		is($result->name, 'TegakiBlog', 'name');
	}
	{
		# good case for code with ID
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=81998" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=81998"></embed></object>};
		ok(ref $validator, 'ref');
		ok($validator->isa('HTML::WidgetValidator'), 'isa');
			my $result = $validator->validate($html);
		ok(defined $result, 'defined');
		ok(ref($result) eq 'HTML::WidgetValidator::Result', 'ref '.ref($result));
		# is($result->code, $html, 'code');
		is($result->name, 'TegakiBlog', 'name');
	}
	{
		# bad case for code with ads:other site
		my $html = q{<script type="text/javascript" src="http://pizza.jp/tegaki/js/tag.js"></script>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case for code non ads:other site
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pizza.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=0" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=0"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case for code with ads and ID:other site
		my $html = q{<script type="text/javascript" src="http://pizza.jp/tegaki/js/tag.js#userID=81998"></script>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case for code with ID:other site
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pizza.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=81998" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=81998"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# good case for code non ads:different size
		my $html = q{<object width="0" height="0"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=0" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=0"></embed></object>};
			my $result = $validator->validate($html);
		ok($validator->isa('HTML::WidgetValidator'), 'isa');
		is($result->name, 'TegakiBlog', 'name');
	}
	{
		# good case for code with ID:different size
		my $html = q{<object width="0" height="0"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=81998" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=81998"></embed></object>};
			my $result = $validator->validate($html);
		ok($validator->isa('HTML::WidgetValidator'), 'isa');
		is($result->name, 'TegakiBlog', 'name');
	}
	{
		# good case for code with ads and ID:other ID
		my $html = q{<script type="text/javascript" src="http://pipa.jp/tegaki/js/tag.js#userID=0"></script>};
			my $result = $validator->validate($html);
		ok($validator->isa('HTML::WidgetValidator'), 'isa');
		is($result->name, 'TegakiBlog', 'name');
	}
	{
		# good case for code with ID:other ID
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=0" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=0"></embed></object>};
			my $result = $validator->validate($html);
		ok($validator->isa('HTML::WidgetValidator'), 'isa');
		is($result->name, 'TegakiBlog', 'name');
	}

	{
		# bad case for code with ads and ID:missing ID 1
		my $html = q{<script type="text/javascript" src="http://pipa.jp/tegaki/js/tag.js#userID="></script>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case for code with ID:missing ID 1
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID="></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}

	{
		# bad case for code with ID:missing ID 2
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars=""></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}

	{
		# bad case for code non ads:undesignate width 1
		my $html = q{<object width="" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=0" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=0"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case for code with ID:undesignate width 1
		my $html = q{<object width="" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=81998" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=81998"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}

	{
		# bad case for code non ads:undesignate width 2
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=0" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="" height="210" FlashVars="ID=0"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case for code with ID:undesignate width 2
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=81998" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="" height="210" FlashVars="ID=81998"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}

	{
		# bad case for code non ads:undesignate height 1
		my $html = q{<object width="150" height=""><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=0" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=0"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case for code with ID:undesignate height 1
		my $html = q{<object width="150" height=""><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=81998" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="210" FlashVars="ID=81998"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}

	{
		# bad case for code non ads:undesignate height 2
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=0" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="" FlashVars="ID=0"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case for code with ID:undesignate height 2
		my $html = q{<object width="150" height="210"><param name="movie" value="http://pipa.jp/tegaki/OBlogParts.swf" /><param name=FlashVars value="ID=81998" /><embed src="http://pipa.jp/tegaki/OBlogParts.swf" width="150" height="" FlashVars="ID=81998"></embed></object>};
			my $result = $validator->validate($html);
		isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
}

__END__
