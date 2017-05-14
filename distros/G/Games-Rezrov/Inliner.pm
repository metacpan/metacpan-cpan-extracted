package Games::Rezrov::Inliner;

# inline a few of the most frequently used z-machine memory access
# calls.  Provides a speed improvement at the cost of more obfuscated
# and heinously non-OO code.  Oh well.

# only works for TRIVIAL code: will break if "arguments" for inlined
# routines contain parens (can't handle nesting)

1;

sub inline {
  my $ref = shift;
  
  my $rep = 'vec($Games::Rezrov::StoryFile::STORY_BYTES, $Games::Rezrov::StoryFile::PC++, 8)';
  $$ref =~ s/GET_BYTE\(\)/$rep/og;
  # replaces StoryFile::get_byte() -- z-machine memory access
  
  $rep = '(vec($Games::Rezrov::StoryFile::STORY_BYTES, $Games::Rezrov::StoryFile::PC++, 8) << 8) + vec($Games::Rezrov::StoryFile::STORY_BYTES, $Games::Rezrov::StoryFile::PC++, 8)';
  $$ref =~ s/GET_WORD\(\)/$rep/og;
  # replaces StoryFile::get_word() -- z-machine memory access

  $rep = 'unpack("S", pack("s", %s))';
  $$ref =~ s/UNSIGNED_WORD\((.*?)\)/sprintf $rep, $1/eog;
  # cast a perl variable into a unsigned 16-bit word (short).
  # Necessary to ensure the sign bit is placed at 0x8000.
  # Replaces unsigned_word() subroutine.
  # WILL ONLY WORK IF NO NESTED PARENS

  $rep = 'unpack("s", pack("s", %s))';
  $$ref =~ s/SIGNED_WORD\((.*?)\)/sprintf $rep, $1/eog;
  # cast a perl variable into a signed 16-bit word (short).
  # replaces signed_word() subroutine.
  # WILL ONLY WORK IF NO NESTED PARENS

  $rep = 'vec($Games::Rezrov::StoryFile::STORY_BYTES, %s, 8)';
  $$ref =~ s/GET_BYTE_AT\((.*?)\)/sprintf $rep, $1/eog;
  # replaces StoryFile::get_byte_at($x) -- memory access
  # WILL ONLY WORK IF NO NESTED PARENS

  $rep = '(vec($Games::Rezrov::StoryFile::STORY_BYTES, %s, 8) << 8) + vec($Games::Rezrov::StoryFile::STORY_BYTES, %s + 1, 8)';
  $$ref =~ s/GET_WORD_AT\((.*?)\)/sprintf $rep, $1, $1/eog;
  # replaces StoryFile::get_word_at($x) -- memory access
  # WILL ONLY WORK IF NO NESTED PARENS
  
}
