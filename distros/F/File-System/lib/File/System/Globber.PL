use Parse::RecDescent;

my $grammar = q(
glob:				match(s)

match:				match_one
|					match_any
|					match_alternative
|					match_collection
|					match_character

match_one: 			'?'
					{ 	$return = bless {}, 'File::System::Glob::MatchOne' }

match_any: 			'*'
					{ 	$return = bless {}, 'File::System::Glob::MatchAny' }

match_alternative:	'{' match_option(s /,/) '}'
					{ 	$return = bless { alternatives => $item[2] }, 'File::System::Glob::MatchAlternative' }

match_option:		/(?:[^,\\}\\\\]|\\\\}|\\\\,|\\\\)+/
					{ 	local $_ = $item[1];
						s/\\\\}/}/g;
						s/\\\\,/,/g;
						s/\\\\\\\\/\\\\/g;
						$return = $_ }

match_collection:  '[' match_class(s) ']'
					{	$return = bless { classes => $item[2] }, 'File::System::Glob::MatchCollection' }

match_class:		/(.)-(.)/
					{	$return = [ $1, $2 ] }
| 					/\\\\]/
					{	$return = "]" }
|					/[^\\]]/
					{	$return = $item[1] }

match_character:	/./
					{	$return = bless { character => $item[1] }, 'File::System::Glob::MatchCharacter' }
);

Parse::RecDescent->Precompile($grammar, 'File::System::Globber');

rename('Globber.pm', $ARGV[0])
	or die "Failed to copy Globber.pm to $ARGV[0].";
