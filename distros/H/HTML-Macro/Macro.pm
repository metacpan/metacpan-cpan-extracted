# HTML::Macro; Macro.pm
# Copyright (c) 2001,2002 Michael Sokolov and Interactive Factory. Some rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package HTML::Macro;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %file_cache %expr_cache);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.29';


# Preloaded methods go here.

use HTML::Macro::Loop;
use Cwd;

# Autoload methods go after =cut, and are processed by the autosplit program.

# don't worry about hi-bit characters
my %char2htmlentity = 
(
    '&' => '&amp;',
    '>' => '&gt;',
    '<' => '&lt;',
    '"' => '&quot;',
);

sub html_encode
{
    $_[0] =~ s/([&><\"])/$char2htmlentity{$1}/g;
    return $_[0];
}

sub collapse_whitespace
{
    my ($buf, $blank_lines_only) = @_;
    my $out = '';
    my $pos = 0;
    my $protect_whitespace = '';
    while ($buf =~ m{(< \s*
                      (/?textarea|/?pre|/?quote)(_?)
                      (?: (?: \s+\w+ \s* = \s* "[^\"]*") |    # quoted attrs
                          (?: \s+\w+ \s* =[^>\"]*) | # attrs w/ no quotes
                          (?: \s+\w+) # attrs with no value
                       ) *
                      >)}sgix)
    {
        my ($match, $tag, $underscore) = ($1, lc $2, $3);
        my $nextpos = pos $buf;
        if ($protect_whitespace)
        {
            $out .= substr ($buf, $pos, $nextpos - $pos);
        }
        else
        {
            my $chunk = substr ($buf, $pos, $nextpos - $pos);
            if (! $blank_lines_only) {
                 # collapse adj white space on a single line
                $chunk =~ s/\s+/ /g;
            }
            # remove blank lines and trailing whitespace; use UNIX line endings
            $chunk =~ s/\s*[\r\n]+/\n/sg;
            $out .= $chunk;
        }
        if ($tag eq "/$protect_whitespace") {
            $protect_whitespace = '';
        } elsif (! $protect_whitespace && $tag !~ m|^/|) {
            $protect_whitespace = $tag;
        }
        $pos = $nextpos;
    }

    # process trailing chunk
    $buf = substr ($buf, $pos) if $pos;
    if (! $blank_lines_only) {
        # collapse adj white space on a single line
        $buf =~ s/\s+/ /g;
    }
    # remove blank lines and trailing whitespace; use UNIX line endings
    $buf =~ s/\s*[\r\n]+/\n/sg;
    $out .= $buf;
}

sub process_cf_quotes
{
    my ($pbuf) = @_;
    $$pbuf =~ s/<!---.*?--->//sg;
    # These will be valid XML:
    $$pbuf =~ s/<!--#.*?#-->//sg;
}

sub doloop ($$)
{
    my ($self, $loop_id, $loop_body, $element) = @_;

    if ($self->{'@attr'}->{'debug'}) {
        print STDERR "HTML::Macro: processing loop $loop_id\n";
    }
    my $p = $self;
    my $loop;
    while ($p) {
        $loop = $$p{$loop_id};
        last if $loop;
        # look for loops in outer scopes
        $p = $p->{'@parent'};
        last if !$p;
        if ($p->isa('HTML::Macro::Loop'))
        {
            $p = $p->{'@parent'};
            die if ! $p;
        }
    }
    if (! $loop ) {
        $self->warning ("no match for loop id=$loop_id");
        return '';
    }
    if (!ref $loop || ! $loop->isa('HTML::Macro::Loop'))
    {
        $self->error ("doloop: $loop (substitution for loop id \"$loop_id\") is not a HTML::Macro::Loop!");
    }
    my $separator;
    if ($element =~ /\bseparator="([^\"]*)"/ || 
        $element =~ /\bseparator=(\S+)/) 
    {
        $separator = $1;
    }
    my $separator_final;
    if ($element =~ /\bseparator_final="([^\"]*)"/ || 
        $element =~ /\bseparator_final=(\S+)/) 
    {
        $separator_final = $1;
    }
    my $collapse = ($element =~ /\scollapse\b/);
    $loop->{'@dynamic'} = $self;    # allow dynamic scoping of macros !
    $loop_body = $loop->doloop ($loop_body, $separator, $separator_final, $collapse);
    #$loop_body = $self->dosub ($loop_body);
    return $loop_body;
}

sub doeval ($$)
{
    my ($self, $attr, $attrval, $body) = @_;
    if ($self->{'@attr'}->{'debug'}) {
        print STDERR "HTML::Macro: processing eval: { $attr $attrval }\n";
    }
    my $htm;
    if ($body) {
        $htm = new HTML::Macro;
        $htm->{'@parent'} = $self;
        $htm->{'@body'} = $body;
        my @incpath = @ {$self->{'@incpath'}};
        $htm->{'@incpath'} = \@incpath; # make a copy of incpath
        $htm->{'@attr'} = $self->{'@attr'};
        $htm->{'@cwd'} = $self->{'@cwd'};
    } else {
        $htm = $self;
    }
    my $package = $self->{'@caller_package'};
    my $result;
    if ($attr eq 'expr') {
        $result = eval " & {package $package; sub { $attrval } } (\$htm)";
    } elsif ($attr eq 'func') {
        $package = $::{$package . '::'};
        my $func = $$package{$attrval};
        eval {
            $result = & {$func} ($htm);
        };
    }
    if ($@) {
        $self->error ("error evaluating $attr '$attrval': $@");
    }
    return $result || '';       # inhibit undefined warnings
}

sub case_fold_match
{
    my ($hash, $key) = @_;
    my $val =
        exists($$hash{$key}) ? (defined($$hash{$key}) ?  $$hash{$key} : '')
            : ( exists ($$hash{lc $key}) ? (defined($$hash{lc $key}) ? $$hash{lc $key} : '')
                : (exists $$hash{uc $key} ? (defined($$hash{uc $key}) ? $$hash{uc $key} : '')
                   : undef) );
    return $val;
}

sub match_token ($$)
{
    my ($self, $var) = @_;

    if ($self->{'@attr'}->{'debug'}) {
        print STDERR "HTML::Macro: matching token $var\n";
    }
    # these are the two styles we've used
    my $val;
    my $dynamic = $self->{'@dynamic'};
    while ($self) 
    {
        # ovalues is also used to store request variables so they override
        # data fetched (later in the processing of a request) from the database
        $val = &case_fold_match ($self->{'@ovalues'}, $var) if $self->{'@ovalues'};
        $val = &case_fold_match ($self, $var) if ! defined ($val);
        return $val if (defined ($val));

        # include outer loops in scope
        $self = $self->parent();
    }
    ## If no lexically-scoped variable matched, check dynamically scoped variables
    # This has the effect of allowing unrelated (orthogonal) loops to be nested
    if ($dynamic) {
        return &match_token ($dynamic, $var);
    }
    return undef;
}

sub dosub ($$)
{
    my ($self, $html) = @_;
    # replace any "word" surrounded by single or double hashmarks: "##".
    # Warning: two tokens of this sort placed right next to each other
    # are indistinguishable from a single token: #PAGE##NUM# could be one
    # token or two: #PAGE# followed by #NUM#.  This code breaks this ambiguity
    # by being greedy.  Probably should change it to be parsimonious and 
    # disallow hashmarks as part of tokens...

    # NOTE: "word" may also be preceded by a single '@' now; this exposes
    # internal values (like @include_body) for substitution

    my $lastpos = 0;
    if ($html =~ /((\#{1,2})(\@?\w+)\2)/sg )
    {
        my ( $matchpos, $matchlen ) = (pos ($html), length ($1));
        my $result = substr ($html, 0, $matchpos - $matchlen);
        while (1)
        {
            my $quoteit = substr($2,1);
            my $var = $3;
            #warn "xxx $quoteit, $var: ($1,$2); (pos,len) = $matchpos, $matchlen";
            my $val = $self->match_token ($var);
            $result .= defined ($val) ? 
                ($quoteit ? &html_encode($val) : $val) : ($2 . $var . $2);
            $lastpos = $matchpos;
            if ($html !~ /\G.*?((\#{1,2})(\@?\w+)\2)/sg)
            {
                $result .= substr ($html, $lastpos);
                return $result;
            }
            ( $matchpos, $matchlen ) = (pos ($html), length ($1));
            $result .= substr ($html, $lastpos,
                               $matchpos - $matchlen - $lastpos);
        }
    }
    return $html;
}

sub findfile
# follow the include path, looking for the file and return an open file handle
{
    my ($self, $fname) = @_;
    if (substr($fname,0,1) eq '/') {
        my @stat = stat $fname;
        return ($fname, $stat[9]) if @stat;
    } else {
        my @incpath = @ {$self->{'@incpath'}};
        push (@incpath, $self->{'@cwd'} . '/') unless ($self->{'@no_local_incpa\
th'});
        while (@incpath)
        {
            my $dir = pop @incpath;
            my @stat = stat $dir . $fname;
            return ($dir . $fname, $stat[9]) if @stat;
        }
    }
    $self->error ("Cannot find file $fname, incpath=" . 
                  join (',',@ {$self->{'@incpath'}})
                  . ", cwd=" . $self->{'@cwd'});
    return ();
}

sub openfile
# open the file, change directories to the file's directory, remembering where
# we came from, and add the file's directory to incpath
{
    my ($self, $path) = @_;
    my @incpath = @ {$self->{'@incpath'}};

    my $cwd = $self->{'@cwd'};

    open (FILE, $path) || $self->error ("Cannot open '$path': $!");

    if ($self->{'@attr'}->{'debug'}) {
        print STDERR "HTML::Macro: opening $path, incpath=@incpath, cwd=$cwd";
    }
    $self->{'@file'} = $path;

    # we will change directories so relative includes work
    # remember where we are so we can get back here

    push @ {$self->{'@cdpath'}}, $cwd;

    my ($dir, $fname);
    if ($path =~ m|(.*)/([^/])+$|) {
        ($dir, $fname) = ($1, $2);
    } else {
        ($dir, $fname) = ('', $path);
    }

    # add our current directory to incpath so includes from other directories
    # will still look here - if $dir is not an absolute path.  Recognizes
    # drive letters even if this is !Windows. oh well

    $dir = "$cwd/$dir" if ($dir !~ m|^([A-Za-z]:)?/|);
    $dir =~ s|//+|/|g;          # remove double slashes

    push @ {$self->{'@incpath'}}, $dir . '/';

    # chdir to where file is
    # chdir $dir || $self->error ("openfile can't chdir $dir (opening $path): $!");

    #print STDERR "openfile: \@cwd=", $dir, "\n";
    $self->{'@cwd'} = $dir;

    return *FILE{IO};
}

sub dodefine
{
    my ($self, $name, $val, $global) = @_;

    # double-evaluation for define:
    $val = $self->process_buf ($val);

    if ($global) {
        $self->set_global ($name, $self->dosub($val));
    } else {
        $self->set ($name, $self->dosub($val));
    }
}

sub doinclude ($$$)
{
    my ($self, $include, $body) = @_;
    my $lastpos = 0;
    my $file = $self->{'@file'};
    $include = $self->dosub ($include);
    if ($include !~ m|<include_?/?\s+file="(.*?)"\s*(asis)?\s*/?>|sgi)
    {
        $self->error ("bad include ($include)");
    }
    my ($filename, $asis) = ($1, $2);
    my $out;
    if ($asis)
    {
        #open (ASIS, $filename) || $self->error ("can't open $filename: $!");
        
        my $buf = $self->readfile ($filename);

        my $lastdir = pop @ {$self->{'@cdpath'}};
        if ($lastdir)
        {
            # chdir $lastdir ;
            $self->{'@cwd'} = $lastdir;
        }
        else {
            delete $self->{'@cwd'};
        }
        # we pushed the included file's directory into incpath when
        # opening it (see openfile); now pop it - we would usu. do this in
        # process
        pop @ {$self->{'@incpath'}};

        $out = $buf;
    } 
    elsif ($body)
    {
        my $inc_body = $self->{'@include_body'};
        $self->{'@include_body'} = $body;
        $out = $self->process ($filename);
        $self->{'@include_body'} = $inc_body;
    }
    else
    {
        $out = $self->process ($filename);
    }
    $self->{'@file'} = $file;
    return $out;
}

sub attr_backwards_compat
{
    my ($self) = @_;
    my $attr = $self->{'@attr'};
    foreach my $key ('debug', 'collapse_whitespace', 'collapse_blank_lines',
                     'precompile')
    {
        $$attr{$key} = $$self{'@' . $key} if defined $$self{'@' . $key};
    }
}

sub eval_if_attrs
{
    my ($self, $attrs, $match, $tag, $nextpos, $package) = @_;
    my $true;
    if ($attrs =~ /^\s* expr \s* = \s* "([^\"]*)" \s*$/six)
    { 
        my $expr = $1 || '';
        $expr = $self->dosub ($expr);
        $true = eval "{ package $package; $expr }";
        if ($@) {
            $self->error ("error evaluating $match (after substitutions: $expr): $@",
                          $nextpos);
        }
    } 
    elsif ($attrs =~ /^\s* (n?)def \s* = \s* "([^\"]*)" \s*$/six)
    {
        my $ndef = $1;
        my $token = $2 || '';
        $true = $self->match_token ($token);
        $true = ! $true if $ndef;
    }
    else
    {
        $self->error ("error parsing '$tag' attributes: $attrs",
                      $nextpos);
    }
    return $true;
}

sub process_buf ($$)
{
    my ($self, $buf) = @_;
    return '' if ! $buf;
    my $out = '';
    my @tag_stack = ();
    my $pos = 0;
    my $quoting = 0;
    my $looping = 0;
    my $true = 1;
    my $emitting = 1;
    my $active = 1;

    &attr_backwards_compat;

    # remove CFM-style quotes: <!--- ... --->
    &process_cf_quotes (\$buf);

    my $underscore = $self->{'@attr'}->{'precompile'} ? '_' : '';
    print STDERR "Entering process_buf: $buf\n" if ($self->{'@attr'}->{'debug'});

    $self->get_caller_info if ! $self->{'@caller_package'};
    my $package = $self->{'@caller_package'};

    while ($buf =~ m{(< \s*
                      (/?loop|/?if|/?include|/?else|/?quote|/?eval|elsif|/?define)$underscore(/?)
                      (   (?: \s+\w+ \s* = \s* "[^\"]*") |    # quoted attrs
                          (?: \s+\w+ \s* =[^>\"]) | # attrs w/ no quotes
                          (?: \s+\w+) # attrs with no value
                       ) * \s*
                      (/?)>)}sgix)
    {
        my ($match, $tag, $slash, $attrs, $slash2) = ($1, lc $2, $3, $4, $5);
        my $nextpos = (pos $buf) - (length ($&));
        $slash = $slash2 if ! $slash; # allow normal XML style
        if (! $slash && $tag eq 'elsif')
        {
            $slash = 1;
            $self->warning ("missing trailing slash for singleton tag $tag", $nextpos);
        }
        $tag .= '/' if $slash;
        $emitting = $true && ! $looping;
        $active = $true && !$quoting && !$looping;
        if ($active)
        {
            $out .= $self->dosub 
                (substr ($buf, $pos, $nextpos - $pos));
            # skip over the matched tag; handling any state changes below
            $pos = $nextpos + length($&);
        }
        elsif ($quoting)
        {
            # ignore everything except quote tags
            if ($tag eq '/quote')
            {
                my $matching_tag = pop @tag_stack;
                $self->error ("no match for tag 'quote'", $nextpos)
                    if (! $matching_tag);
                my ($start_tag, $attr) = @$matching_tag;
                $self->error ("start tag $start_tag ends with end tag 'quote'",
                              $nextpos)
                    if ($start_tag ne 'quote');
                if ($emitting && !$attr)
                {
                    # here we'ved popped out of a bunch of possibly nested 
                    # quotes: !$attr means this is the outermost one and
                    # $emitting means we're neither in a false condition nor
                    # are we in an accumulating loop (which will be processed
                    # later in a recursion).
                    
                    # the next line says to emit the </quote> tag if we are
                    # in a "preserved" quote:
                    my $endpos = ($quoting == 2) ? ($nextpos + length($match))
                        : $nextpos;
                    $out .= substr ($buf, $pos, $endpos - $pos);
                    $pos = $nextpos + length($match);
                }
                $quoting = $attr;
            }
            elsif ($tag eq 'quote')
            {
                push @tag_stack, [ 'quote', $quoting, $nextpos ];
            }
            next;
        }
        elsif (!$looping)
            # if looping, just match tags until we find the right matching 
            # end loop; don't process anything except quotes, since we might 
            # quote a loop tag!
            # Rather, leave that for a recursion.
        {
            # die if $true;    # debugging test
            # if we're in a false conditional, don't emit anything and skip over
            # the matched tag
            $pos = $nextpos + length($match);
        }
        if ($tag eq 'loop' || $tag eq 'eval' || $tag eq 'include' || $tag eq 'define')
            # loop and eval are similar in their lexical force - both are block-level
            # tags that force embedded scopes.  Therefore their contents are processed
            # in a nested evaluation, and not here.
            # The effect on eval is that an eval nested in a loop
        {
            my ($attr, $attrval);
            if ($tag eq 'loop') {
                $match =~ /id="([^\"]*)"/ || $match =~ /id=(\S+)/ ||
                    $self->error ("loop tag '$match' has no id", $nextpos);
                $attr = $1;
		$attrval = $match;
            } elsif ($tag eq 'eval') {
                $match =~ /(expr|func)="([^\"]*)"/ || 
                    $self->error ("eval tag '$match' has no expr or func", $nextpos);
                ($attr, $attrval) = ($1, $2);
            } elsif ($tag eq 'include') {
                $attr = $match;
                $attrval = undef;
            } elsif ($tag eq 'define') {
                $match =~ /(name)="([^\"]*)"/ || 
                    $self->error ("define tag '$match' has no name", $nextpos);
                $attr = $match;
                $attrval = $2;
            }
            push @tag_stack, [$tag, $attr, $nextpos, $attrval];
            ++$looping;
            next;
        }
        if ($tag eq '/loop' || $tag eq '/eval' || $tag eq '/include' || $tag eq '/define')
        {
            my $matching_tag = pop @tag_stack;
            $self->error ("no match for tag '$tag'", $nextpos)
                if ! $matching_tag;
            my ($start_tag, $attr, $tag_pos, $attrval) = @$matching_tag;
            $self->error ("start tag '$start_tag' (at char $tag_pos) ends with end tag '$tag'",
                          $nextpos)
                if ($start_tag ne substr ($tag, 1));

            -- $looping;
            if ($true && !$looping && !$quoting)
            {
                my $body = substr ($buf, $pos, $nextpos-$pos);
                if ($tag eq '/loop') {
                    $attr = $self->dosub ($attr);
                    $out .= $self->doloop ($attr, $body, $attrval);
                } elsif ($tag eq '/eval') {
                    # tag=eval
                    $attrval = $self->dosub ($attrval);
                    $out .= $self->doeval ($attr, $attrval, $body);
                } elsif ($tag eq '/include') {
                    my $incbody = #eval { 
                        $self->process_buf ($body); 
                    #};
                    &error ("error processing included file $attr: $@") 
                        if ($@);
                    $out .= $self->doinclude ($attr, $incbody);
                } elsif ($tag eq '/define') {
                    $self->dodefine($attrval, $body);
                }
                $pos = $nextpos + length($match);
            }
            next;
        }
        if ($tag eq 'quote')
        {
            push @tag_stack, ['quote', $quoting, $nextpos];
            if ($match =~ /preserve="([^\"]*)"/)
            {
                my $expr = $1 || '';
                $expr = $self->dosub ($expr);
                my $result = eval "{ package $package; $expr }";
                if ($result)
                {
                    $quoting = 2;
                    # why ?
                    $pos = $nextpos if !$looping;
                }
                else
                {
                    if ($match =~ /expr="([^\"]*)"/)
                    {
                        $expr = $1 || '';
                        $expr = $self->dosub ($expr);
                        $result = eval "{ package $package; $expr }";
                        if ($result)
                        {
                            $quoting = 1;
                        }
                    } else {
                        $quoting = 1;
                    }
                }
                if ($@) {
                    $self->error ("error evaluating $match (after substitutions: $expr): $@",
                            $nextpos);
                }
            } 
            else {
                $quoting = 1;
            }
            next;
        }
        if ($tag eq '/quote')
        {
            my $matching_tag = pop @tag_stack;
            $self->error ("no match for tag '$tag'", $nextpos)
                if ! $matching_tag;
            my ($start_tag, $attr, $tag_pos) = @$matching_tag;
            $self->error ("start tag '$start_tag' ends with end tag '$tag'",
                          $nextpos)
                if ($start_tag ne substr ($tag, 1));
            next;
        }
        next if $looping;       # ignore the rest of these tags while looping

        if (substr($tag, 0, 1) eq '/') 
            # process end tags; match w/start tags and handle state changes
        {
            my $matching_tag = pop @tag_stack;
            $self->error ("no match for tag '$tag'", $nextpos)
                if ! $matching_tag;
            my ($start_tag, $attr, $tag_pos) = @$matching_tag;
            if ($tag eq '/if' && $start_tag eq 'elsif') {
                $matching_tag = pop @tag_stack;
                $self->error ("no match for tag '/if'", $nextpos)
                    if ! $matching_tag;
                ($start_tag, $attr, $tag_pos) = @$matching_tag;
            }
            $self->error ("start tag '$start_tag' ends with end tag '$tag'",
                          $nextpos)
                if ($start_tag ne substr ($tag, 1));

            if ($start_tag eq 'if')
            {
                $true = $attr;
            }
        }
        elsif ($tag eq 'if')
        {
            push @tag_stack, ['if', $true, $nextpos] ;
            if ($active) {
                $true = $self->eval_if_attrs 
                    ($attrs, $match, $tag, $nextpos, $package);
            }
        }
        elsif ($tag eq 'elsif/') {
            my $top = $tag_stack[$#tag_stack];
            my $last_tag = $$top[0];
            if ($last_tag eq 'if') {
                $top = ['elsif', $$top[1], $true];
                push @tag_stack, $top;
            } elsif ($last_tag eq 'elsif') {
                # if *any* of the foregoing if/elsif clauses have been true
                $$top[2] ||= $true;
            } else {
                $self->error ("<elsif /> not in <if>", $nextpos);
            }
            if (!$looping && $$top[1] && $$top[2]) {
                # if an earlier if/elsif was true, and we are not overshadowed
                # by an enclosing scope, this one is false.
                $true = 0;
            }
            elsif (!$looping && $$top[1] && ! $$top[2]) {
                # if all previous if/elsifs were false, this one might still be true
                $true = $self->eval_if_attrs ($attrs, $match, $tag, $nextpos, $package);
            }
        }
        elsif ($tag eq 'else/' || $tag eq 'else')
        {
            my $top = $tag_stack[$#tag_stack];
            my $last_tag = $$top[0];

            # if we are embedded in a false condition, it overrides us: 
            # don't change false based on this else.  Also, don't evaluate
            # anything while looping: postpone for recursion.

            if ($last_tag eq 'elsif') {
                
                my $if_elsif_any_true = $$top[2] || $true;
                pop @tag_stack;
                my $top = $tag_stack[$#tag_stack];
                # check falsitude of enclosing scope
                $true = (! $looping && ! $if_elsif_any_true) if $$top[1];
            } elsif ($last_tag eq 'if') {
                $true = ! $true if (! $looping && $$top[1]);
            } else {
                $self->error ("<else /> not in <if>", $nextpos);
            }

            push @tag_stack, ['else', $true] if $tag eq 'else';
        }

        # skip these tags if false since they don't effect the truth value:
        next if !$active;

        if ($tag eq 'include/')
        {
            # singleton (empty) include
            $out .= $self->doinclude ($match);
        }
        elsif ($tag eq 'define/')
        {
            $match =~ /name="([^\"]*)"/ || 
                $self->error ("no name attr for define tag in '$match'",
                              $nextpos);
            my ($name) = $1;
            $match =~ /value="([^\"]*)"/ || 
                $self->error ("no value attr for empty define tag in '$match'",
                              $nextpos);
            my ($val) = $1;
            my ($global) = ($match =~ / global(?:="global")?/);
            $self->dodefine($name, $val, $global);
        }
        elsif ($tag eq 'eval/') {
            if ($match =~ /expr="([^\"]*)"/) {
                my $expr = $self->dosub ($1);
                $self->doeval ('expr', $expr);
            } elsif ($match =~ /func="(\w+)"/) {
                $self->doeval ('func', $1);
            } else {
                $self->error ("eval tag must have valid expr or func attribute", $nextpos);
            }
        }
    }
    # process trailer
    while (@tag_stack)
    {
        my $tag = pop @tag_stack;
        $self->error ("EOF while still looking for close tag for " . $$tag[0]
                      . '(' . $$tag[1] .')', $$tag[2]);
    }
    $out .= $self->dosub (substr ($buf, $pos));
    # remove extra whitespace

    if ($self->{'@attr'}->{'collapse_whitespace'})
    {
        # collapse adjacent white space
        $out = &collapse_whitespace ($out, undef);
    }
    elsif ($self->{'@attr'}->{'collapse_blank_lines'})
    {
        # remove blank lines
        $out = &collapse_whitespace ($out, 1);
    }
    print STDERR "Exiting process_buf: $out\n" if ($self->{'@attr'}->{'debug'});
    return $out;
}

sub readfile
{
    my ($self, $fname) = @_;

    $self->{'@cwd'} = cwd if ! $self->{'@cwd'};
    my $cwd = $self->{'@cwd'};
    my $key = $cwd . '/' . $fname;

    my ($path, $mtime) = $self->findfile ($fname);
    if (!$path) {
        $self->error ("$fname not found: incpath=(" . join (',',@{$$self{'@incpath'}}) . ")");
        return;
    }
    if ($self->{'@attr'}->{'cache_files'} && exists $file_cache{$key}
        && $file_cache{$key .  '@mtime'} >= $mtime)
    {
        #print STDERR "readfile CACHED (file=", $$self{'@file'}, ") $key\n";

        # the name of the file
        $$self{'@file'} = $file_cache{$key . '@file'};

        # the absolute path of the file's directory
        push @{$$self{'@incpath'}}, $file_cache{$key . '@incpath_new'};

        # the absolute path of the enclosing file's directory;
        # where we chdir when we're done processing this file
        push @{$$self{'@cdpath'}}, $file_cache{$key . '@cdpath_new'};

        # Isn't this also the absolute path of the file's directory?
        $$self{'@cwd'} = $file_cache{$key . '@cwd'};

        # chdir $$self{'@cwd'};

        # return the contents of the file
        return $file_cache{$key};
    }

    #print STDERR "readfile $key\n";
    my $fh = $self->openfile ($path);

    #open (HTML, $fname) || $self->error ("can't open $fname: $!");
    my $separator = $/;
    undef $/;
    my $body = <$fh>;
    $/ = $separator;
    close $fh;

    # remove extra whitespace
    if ($self->{'@attr'}->{'collapse_whitespace'})
    {
        # collapse adjacent white space
        $body = &collapse_whitespace ($body, undef);
    }
    elsif ($self->{'@attr'}->{'collapse_blank_lines'})
    {
        # remove blank lines
        $body = &collapse_whitespace ($body, 1);
    }

    if ($self->{'@attr'}->{'cache_files'})
    {
        $file_cache{$key} = $body;
        $file_cache{$key . '@file'} = $$self{'@file'};
        my $list = $$self{'@incpath'};
        $file_cache{$key . '@incpath_new'} = $$list[$#$list];
        $list = $$self{'@cdpath'};
        $file_cache{$key . '@cdpath_new'} = $$list[$#$list];
        $file_cache{$key . '@cwd'} = $$self{'@cwd'};
        $file_cache{$key .  '@mtime'} = $mtime;
    }
    return $body;
    #print STDERR "cwd=", $$self{'@cwd'}, "\n";

    #warn "nothing read from $fname" if ! $$self{'@body'};
}

sub process ($$)
{
    my ($self, $fname) = @_;

    &attr_backwards_compat;

    $$self{'@body'} = &readfile ($self, $fname) if ($fname);

    my $result =  $self->process_buf ($$self{'@body'});
    
    my $lastdir = pop @ {$self->{'@cdpath'}};
    if ($lastdir)
    {
        #print STDERR "popping up to $lastdir\n";
        # chdir $lastdir ;
        $self->{'@cwd'} = $lastdir;
    }
    else {
        delete $self->{'@cwd'};
    }
    pop @ {$self->{'@incpath'}};

    return $result;
}

sub print ($$)
{
    # warn "gosub $_[0] \n";
    my ($self, $fname) = @_;

    print "Cache-Control: no-cache\n";
    print "Pragma: no-cache\n";
    print "Content-Type: text/html\n\n";
    print &process;
}

sub error
{
    my ($self, $msg, $pos) = @_;
    $self->get_caller_info if ! $self->{'@caller_package'};
    $msg = "HTML::Macro: $msg\n";
    $msg .= "parsing " . $self->{'@file'} if ($self->{'@file'});
    #$msg .= " near char $pos" if $pos;
    if ($pos) {
        my $line = 1;
        my $linepos = 0;
        my $body = $$self{'@body'};
        while ($body =~ /\n/sg && pos $body <= $pos) {
            ++$line;
            $linepos = pos $body;
        }
        my $charpos = ($pos - $linepos);
        $msg .= " on line $line, char $charpos\n\n";
        $msg .= substr($body, $linepos, ((pos $body) - $linepos));
    }
    die "$msg\ncalled from " . $self->{'@caller_file'} . ", line " . $self->{'@caller_line'} . "\n";
}

sub warning
{
    my ($self, $msg, $pos) = @_;
    $self->get_caller_info if ! $self->{'@caller_package'};
    $msg = "HTML::Macro: $msg";
    $msg .= " parsing " . $self->{'@file'} if ($self->{'@file'});
    if ($pos) {
        my $line = 1;
        my $linepos = 0;
        my $body = $$self{'@body'};
        while ($body =~ /\n/sg && pos $body <= $pos) {
            ++$line;
            $linepos = pos $body;
        }
        my $charpos = ($pos - $linepos);
        $msg .= " on line $line, char $charpos\n\n";
        $msg .= substr($body, $linepos, ((pos $body) - $linepos));
    }
    warn "$msg\ncalled from " . $self->{'@caller_file'} . ", line " . $self->{'@caller_line'} . "\n";
}

sub set ($$)
{
    my $self = shift;
    while ($#_ > 0) {
        $$self {$_[0]} = $_[1];
        shift;
        shift;
    }
    warn "odd number of arguments to set" if @_;
}

sub parent ($$)
{
    my $self = shift;
    $self = $self->{'@parent'};
    return undef if !$self;
    # parent may be either an HTML::Macro or an HTML::Macro::Loop
    if ($self->isa('HTML::Macro::Loop'))
    {
        $self = $self->{'@parent'};
        if ( ! $self ) {
            warn "found an orphaned HTML::Macro::Loop" ;
            return undef;
        }
    }
    return $self;
}

sub top ($$)
{
    my $self = shift;
    my $parent;
    while (my $parent = $self->{'@parent'}) {
        $self = $parent;
    }
    return $self;
}

sub set_global ($$)
{
    my $self = shift;
    $self->top()->set (@_);
}

sub set_ovalue ($$)
{
    my $self = shift;
    while ($#_ > 0) {
        $self->{'@ovalues'} {$_[0]} = $_[1];
        shift;
        shift;
    }
    warn "odd number of arguments to set" if @_;
}

sub push_incpath ($ )
{
    my ($self) = shift;
    $self->{'@cwd'} = cwd if ! $self->{'@cwd'};
    while (my $dir = shift)
    {
        $dir .= '/' if $dir !~ m|/$|;
        if ($dir !~  m|^(?:[A-Za-z]:)?/|)
        {
            # turn into an absolute path if not already
            # allow DOS drive letters at the start
            $dir = $self->{'@cwd'} . '/' . $dir;
        }
        push @ {$self->{'@incpath'}}, $dir;
    }
}

sub set_hash ($ )
{
    my ($self, $hash) = @_;
    while (my ($var, $val) = each %$hash)
    {
        $$self {$var} = defined($val) ? $val : '';
    }
}

sub get ($ )
# finds values in enclosing scopes and uses macro case-collapsing rules; ie
# matches $var, $uc var, or lc $var
{
    my ($self, $var) = @_;
    return $self->match_token ($var);
}

sub declare ($@)
# use this to indicate which vars are expected on this page.
# Just initializes the hash to have zero for all of its args
# *if the variable is not already set*
{
    my ($self, @vars) = @_;
    for my $var (@vars) {
        $self->{$var} = '' if ! defined ($self->{$var});
    }
}

sub get_caller_info ($ )
{
    my ($self) = @_;
    my ($caller_file, $caller_line);
    my $stack_count = 0;
    my $pkg;
    do {
        ($pkg, $caller_file, $caller_line) = caller ($stack_count++);
    }
    # ignore HTML::Macro and HTML::Macro::Loop
    while ($pkg =~ /HTML::Macro/);

    $self->{'@caller_package'} = $pkg;
    $self->{'@caller_file'} = $caller_file;
    $self->{'@caller_line'} = $caller_line;
}

sub new ($$$ )
{
    my ($class, $fname, $attr) = @_;
    my $self = { };
    $self->{'@incpath'} = [ ];
    $self->{'@cwd'} = cwd;

    if ($attr) {
        if (ref $attr ne 'HASH') {
            $self->error ('third argument (attr) to new must be hash ref');
        }
        $self->{'@attr'} = $attr;
    } else {
        $self->{'@attr'} = {};
    }

    bless $self, $class;

    $$self{'@body'} = &readfile($self, $fname) if ($fname);

    return $self;
}

sub new_loop ()
{
    my ($self, $name, @loop_vars) = @_;
    my $new_loop = HTML::Macro::Loop->new($self);
    if ($name) {
        $self->set ($name, $new_loop);
        if (@loop_vars) {
            $new_loop->declare (@loop_vars);
        }
    }
    return $new_loop;
}

sub keys ()
{
    my ($self) = @_;
    my @keys = grep /^[^@]/, keys %$self;
    push @keys, keys % {$self->{'@ovalues'}} if $self->{'@ovalues'};
    push @keys, $self->parent()->keys() if $self->parent();
    return @keys;
}

1;
__END__

=head1 NAME

HTML::Macro - process HTML templates with loops, conditionals, macros and more!

=head1 SYNOPSIS

  use HTML::Macro;
  $htm = new HTML::Macro ('template.html');
  $htm->print;

  sub myfunc {
    $htm->declare ('var', 'missing');
    $htm->set ('var', 'value');
    return $htm->process;
  }

  ( in template.html ):

  <html><body>
    <eval expr="&myfunc">
      <if def="missing">
        Message about missing stuff...
      <else />
        Var's value is #var#.
      </if>
    </eval>
  </body></html>

=head1 DESCRIPTION

HTML::Macro is a module to be used behind a web server (in CGI scripts). It
provides a convenient mechanism for generating HTML pages by combining
"dynamic" data derived from a database or other computation with HTML
templates that represent fixed or "static" content of a page.

There are many different ways to accomplish what HTML::Macro does,
including ASP, embedded perl, CFML, etc, etc. The motivation behind
HTML::Macro is to keep everything that a graphic designer wants to play
with *in a single HTML template*, and to keep as much as possible of what a
perl programmer wants to play with *in a perl file*.  Our thinking is that
there are two basically dissimilar tasks involved in producing a dynamic
web page: graphic design and programming. Even if one person is responsible
for both tasks, it is useful to separate them in order to aid clear
thinking and organized work.  I guess you could say the main motivation for
this separation is to make it easier for emacs (and other text processors,
including humans) to parse your files: it's yucky to have a lot of HTML in
a string in your perl file, and it's yucky to have perl embedded in a
special tag in an HTML file.

HTML::Macro began with some simple programming constructs: macro
expansions, include files, conditionals, loops and block quotes.  Since
then we've added very little: only a define tag to allow setting values and
an eval tag to allow perl function calls in a nested macro scope.  Our
creed is "less is more, more or less."

HTML::Macro variables will look familiar to C preprocessor users or
especially to Cold Fusion people.  They are always surrounded with single
or double hash marks: "#" or "##".  Variables surrounded by double hash
marks are subject to html entity encoding; variables with single hash marks
are substituted "as is" (like single quotes in perl or UNIX shells).
Conditionals are denoted by the <if> and <else> tags, and loops by the
<loop> tag.  Quoting used to be done using a <quote> tag, but we now
deprecate that in favor of the more familiar CFML quoting syntax: <!---
--->.

=head1 Basic Usage:

Create a new HTML::Macro:

    $htm = new HTML::Macro  ('templates/page_template.html', { 'collapse_whitespace' => 1 });

The first (filename) argument is optional.  If you do not specify it now,
you can do it later, which might be useful if you want to use this
HTML::Macro to operate on more than one template.  If you do specify the
template when the object is created, the file is read in to memory at that
time.

The second (attribute hash) argument is also optional, but you have to set
it now if you want to set attributes.  See Attributes below for a list of
attributes you can set.

Optionally, declare the names of all the variables that will be substituted
on this page.  This has the effect of defining the value '' for all these
variables.

  $htm->declare ('var', 'missing');

Set the values of one or more variables using HTML::Macro::set.

  $htm->set ('var', 'value', 'var2', 'value2');

Note: variable names beginning with an '@' are reserved for internal use.  

Get previously-set values using get:

  $htm->get ('var');  # returns 'value'
  $htm->get ('blah');  # returns undefined

get also returns values from enclosing scopes (see Scope below).

  $htm->keys() returns a list of all defined macro names.

Or use HTML::Macro::set_hash to set a whole bunch of values at once.  Typically
used with the value returned from a DBI::fetchrow_hashref.

  $htm->set_hash ( {'var' => 'value', 'var2' => 'value2' } );

Finally, process the template and print the result using HTML::Macro::print,
or save the value return by HTML::Macro::process.  

    open CACHED_PAGE, '>page.html';
    print CACHED_PAGE, $htm->process;
    # or: print CACHED_PAGE, $htm->process ('templates/page_template.html');
    close CACHED_PAGE;
 
    - or in some contexts simply: 

    $htm->print; 
    or
    $htm->print ('test.html');


    However note this would not be useful for printing a cached page since
    as a convenience for use in web applications HTML::Macro::print prints
    some HTTP headers prior to printing the page itself as returned by
    HTML::Macro::process.

=head1 Macro Expansion

HTML::Macro::process attempts to perform a substitution on any word
beginning and ending with single or double hashmarks (#) , such as
##NAME##.  A word is any sequence of alphanumerics and underscores.  If the
HTML::Macro has a matching variable, its value is substituted for the word
in the template everywhere it appears.  A matching variable is determined
based on a case-folding match with precedence as follows: exact match,
lower case match, upper case match.  HTML::Macro macro names are case
sensitive in the sense that you may define distinct macros whose names
differ only by case.  However, matching is case-insensitive and follows the
above precedence rules.  So :

    $htm->set ('Name', 'Mike', 'NAME', 'MIKE', 'name', 'mike');

results in the following substitutions:

    Name => Mike
    NAME => MIKE
    name => mike
    NAme => mike (same for any other string differing from 'name' only by case).

If no value is found for a macro name, no substitution is performed, and
this is not treated as an error.  This allows templates to be processed in
more than one pass.  Possibly it would be useful to be able to request
notification if any variables are not matched, or to request unmatched
variables be mapped to an empty string.  However the convenience seems to
be outweighed by the benefit of consistency since it easy to get confused
if things like undefined variables are handled differently at different
times.

A typical usage is to stuff all the values returned from
DBI::fetchrow_hashref into an HTML::Macro.  Then SQL column names are to be
mapped to template variables.  Databases have different case conventions
for column names; providing the case insensitivity and stripping the
underscores allows templates to be written in a portable fashion while
preserving an upper-case convention for template variables.

=head2 HTML entity quoting

Variables surrounded by double delimiters (##) are subject to HTML entity
encoding.  That is, >, <, & and "" occuring in the variables value are
replaced by their corresponding HTML entities.  Variables surrounded by
single delimiters are not quoted; they are substituted "as is"

=head1 Conditionals

Conditional tags take one of the following forms:

<if expr="perl expression"> 
 HTML block 1
<else/>
 HTML block 2
</if>

or

<if expr="perl expression"> 
 HTML block 1
<else>
 HTML block 2
</else>
</if>

or simply

<if expr="perl expression"> 
 HTML block 1
</if>

Conditional tags are processed by evaluating the value of the "expr"
attribute as a perl expression.  The entire conditional tag structure is
replaced by the HTML in the first block if the expression is true, or the
second block (or nothing if there is no else clause) if the expressin is
false.

Conditional expressions are subject to variable substitution, allowing for
constructs such as:

You have #NUM_ITEMS# item<if "#NUM_THINGS# > 1">s</if> in your basket.

=head2 ifdef

HTML::Macro also provides the <if def="variable-name"> conditional.  This
construct evaluates to true if variable-name is defined and has a true
value.  It might have been better to name this something different like <if
set="variable"> ? Sometimes there is a need for if (defined (variable)) in
the perl sense.  Also we occasionally want <if ndef="var"> but just use <if
def="var"><else/> instead which seems adequate if a little clumsy.

=head1 File Interpolation

It is often helpful to structure HTML by separating commonly-used chunks
(headers, footers, etc) into separate files.  HTML::Macro provides the
<include /> tag for this purpose.  Markup such as <include file="file.html"
/> gets replaced by the contents of file.html, which is itself subject to
evaluation by HTML::Macro.  If the "asis" attribute is present: <include/
file="quoteme.html" asis>, the file is included "as is"; without any
further evaluation.

HTML::Macro also supports an include path.  This allows common "part" files
to be placed in a single central directory.  HTML::Macro::push_incpath adds
to the path, as in $htm->push_incpath ("/path/to/include/files").  The
current directory (of the file being processed) is always checked first,
followed by each directory on the incpath.  When paths are added to the
incpath they are always converted to absolute paths, relative to the
working directory of the invoking script.  Thus, if your script is running
in "/cgi-bin" and calls push_incpath("include"), this adds
"/cgi-bin/include" to the incpath. (Note that HTML::Macro never calls chdir
as part of an effort to be thread-safe).

Also note that during the processing of an included file, the folder in
which the included file resides is pushed on to the incpath.  This means
that relative includes work as you would expect in included files; a file
found in a directory relative to the included file takes precedence over
one found in a directory relative to the including file (or HTML::Macros
global incpath).

=head1 Loops

    The <loop> tag and the corresponding HTML::Macro::Loop object provide
for repeated blocks of HTML, with subsequent iterations evaluated in
different contexts.  Typically you will want to select rows from a database
(lines from a file, files from a directory, etc), and present each
iteration in succession using identical markup.  You do this by creating a
<loop> tag in your template file containing the markup to be repeated, and
by creating a correspondingly named Loop object attached to the HTML::Macro
and containing all the data to be interpolated.  Note: this requires all
data to be fetched and stored before it is applied to the template; there
is no facility for streaming data.  For the intended use this is not a
problem.  However it militates against using HTML::Macro for text
processing of very large datasets.

  <loop id="people">
    <tr><td>#first_name# #last_name#</td><td>#email#</td></tr>
  </loop>

    The loop tag allows the single attribute "id" which can be any
    identifier.  Loop tags may be nested.  If during processing no matching
    loop object is found, a warning is produced and the tag is simply
    ignored.

  $htm = new HTML::Macro;
  $loop = $htm->new_loop('people', 'id', 'first_name', 'last_name', 'email');
  $loop->push_array (1, 'frank', 'jones', 'frank@hotmail.com');

  Create a loop object using HTML::Macro::new_loop (or
  HTML::Macro::Loop::new_loop for a nested loop).  The first argument is
  the id of the loop and must match the id attribute of a tag in the
  template (the match is case sensitive).  The remaining arguments are the
  names of loop variables.

  Append loop iterations (rows) by calling push_array with an array of
  values corresponding to the loop variables declared when the loop was
  created.

  An alternative is to use push_hash, which is analogous to
HTML::Macro::set_hash; it sets up multiple variable substitutions.  If you
use push_hash you don't have to declare the names of the variables when you
create the loop object.  This allows them to be taken out of a hash and
bound late, for example by names returned in a database query.

  pushall_arrays is a shortcut that allows a number of loop iterations to
be pushed at once.  It is typically used in conjunction with
DBI::selectall_arrayref.

  is_empty returns a true value iff the loop has at least one row.

  keys returns a list of variable names defined in the (last row of the)
  loop.

=head1 Eval

  <eval expr="perl expression"> ... </eval>

  You can evaluate arbitrary perl expressions (as long as you can place
  them in an XML attribute between double quotes!).  The expression is
  subject to macro substition, placed in a block and invoked as an
  anonymous function whose single argument is an HTML::Macro object
  representing the nested scope.  Any values set in the perl expression
  thus affect the markup inside the eval tag.  The perl is evaluated after
  setting the package to the HTML::Macro caller's package.

  Note: typically we only use this to make a function call, and it would
  probably be more efficient to optimize for that case - look for the
  special case <eval function=""> to be implemented soon.  Also we might
  like to provide a singleton eval that would operate in the current scope:
  <eval function="perl_function" />.


=head1 Scope

Each of the tags include, eval and loop introduce a nested "local" lexical
scope.  Within a nested scope, a macro definition overrides any same-named
macro in the enclosing scope and the value of the macro outside the nested
scope is unaffected.  This is generally the expected behavior and makes it
possible to write modular code.

Sometimes desirable to set values at a global scope when operating in a
nested scope.  You do this using set_global.  set_global is totally
analogous to set, but sets values in the outermost scope, whatever the
current scope.

Another related function is set_ovalue.  Set_ovalue sets values in a
parallel scope that takes precedence over the default scope (think
"overridding" value).  We use set_ovalue to place request variables in a
privileged scope so that their values override values fetched from the
datbase.  Each nested lexical scope really contains two name spaces -
values and ovalues, with ovalues taking precedence.  However, an inner
scope always takes precedence over an outer scope.

element Variable substitution
within a loop follows the rule that loop keys take precedence over "global"
variables set by the enclosing page (or any outer loop(s)).

=head1 Define

You can set the value of a variable using the <define /> tag which requires
two attributes: name and value.  This is only occasionally useful since
mostly we set variable values in perl.  An example might be setting a value
that is constant in an outer context but variable in an inner context, such
as a navigation state:

<define name="nav_state" value="about" />
<include file="nav.html" />

We might want a more convenient syntax for this such as 

<define variable="value" />

but this seems somehow contravening the XML ideal since it would allow
arbitrary attributes; we could never write any sort of DTD or schema.  And
this whole feature is so little used that it doesn't seem worth it.

=head1 Quoting

For inserting block quotes in your markup that will be completely removed
during macro processing, use <!--- --->.

Also note that all macro and tag processing can be inhibited by the use of
the "<quote>" tag.  Any markup enclosed by <quote> ... </quote> is passed
on as-is.  However please don't rely on this as it is not all that useful
and may go away.  The only real use for this was to support a
pre-processing phase that could generate templates.  A new feature supports
this better: any of the HTML::Macro tags may be written with a trailing
underscore, as in <if_ expr="..."> ... </if_>.  Tags such as this are
processed only if the preference variable '@precompile' is set, in which
case unadorned tags are ignored.

=head1 Attributes

These are user-controllable attributes that affect the operation of
HTML::Macro in one way or another.

=head3 debug 

Set to a true value, produces various diagnostic information on STDERR.  Default is false.

=head3 precompile 

If set, (only) tags with trailing underscores will be processed. Default is false.

=head3 collapse_whitespace, collapse_blanklines

 If you set '@collapse_whitespace' the processor will collapse all
  adjacent whitespace (including line terminators) to a single space.  An
  exception is made for markup appearing within <textarea>, <pre> and
  <quote> tags.  Similarly, setting '@collapse_blank_lines' (and not
  '@collapse_whitespace', which takes precedence), will cause adjacent line
  terminators to be collapsed to a single newline character.  We use the
  former for a final pass in order to produce efficient HTML, the latter
  for the preprocessor, to improve the readability of generated HTML with a
  lot of blank lines in it.  Default for both is false.

=head3 cache_files

If set, files are read into and retrieved from an in-memory cache to
improve performance for long-lived applications such as mod_perl and for
situations in which the same file is read repeatedly during the processing
of a single template.  This definitely helped in a scenario involving an
include in side a loop, but it's not immediately clear why given that the
operating system is probably caching recently-read files in memory anyway.
The cache checks file modification times and reloads when a file changes.
There is currently no limit to file cache size, which should definitely get
changed.

=head1 Idiosyncracies

For hysterical reasons HTML::Macro allows a certain kind of non-XML; singleton tags are allowed to be written with the trailing slash immediately following the tag and separated from the closing > by white space.  EG:

    <include/ file="foo"> is OK

whereas XML calls for

    <include file="foo" /> (which is also allowed here).


HTML::Macro is copyright (c) 2000-2004 by Michael Sokolov and Interactive
Factory (sm).  Some rights may be reserved.  This program is free software;
you can redistribute it and/or modify it under the same terms as Perl
itself.

=head1 AUTHOR

Michael Sokolov, sokolov@ifactory.com

=head1 SEE ALSO HTML::Macro::Loop

perl(1).

=cut
