use strict;
use warnings;
use Test::More tests => 24;
use Markdown::Simple;

# Test basic functionality
{
    my $result = markdown_to_html("Hello world");
    is($result, "<div>Hello world</div>", "Plain text passes through");
}

# Test headers
{
    my $result = markdown_to_html("# Header 1");
    is($result, "<div><h1>Header 1</h1></div>", "H1 header");
    
    $result = markdown_to_html("## Header 2");
    is($result, "<div><h2>Header 2</h2></div>", "H2 header");
    
    $result = markdown_to_html("### Header 3");
    is($result, "<div><h3>Header 3</h3></div>", "H3 header");
}

# Test bold
{
    my $result = markdown_to_html("**bold text**");
    is($result, "<div><strong>bold text</strong></div>", "Bold text");
}

# Test italic
{
    my $result = markdown_to_html("*italic text*");
    is($result, "<div><em>italic text</em></div>", "Italic text");
}

# Test inline code
{
    my $result = markdown_to_html("`code`");
    is($result, "<div><code>code</code></div>", "Inline code");
}

# Test fenced code blocks
{
    my $result = markdown_to_html("```\ncode block\n```");
    is($result, "<div><pre><code>\ncode block\n</code></pre></div>", "Fenced code block");
    
    $result = markdown_to_html("```javascript\nvar x = 1;\n```");
    is($result, "<div><pre><code class=\"language-javascript\">\nvar x = 1;\n</code></pre></div>", "Fenced code block with language");
}

# Test links
{
    my $result = markdown_to_html("[link text](http://example.com)");
    is($result, "<div><a href=\"http://example.com\">link text</a></div>", "Link");
}

# Test images
{
    my $result = markdown_to_html("![alt text](image.jpg)");
    is($result, "<div><img alt=\"alt text\" src=\"image.jpg\" /></div>", "Image");
}

# Test strikethrough
{
    my $result = markdown_to_html("~~strikethrough~~");
    is($result, "<div><del>strikethrough</del></div>", "Strikethrough");
}

# Test task lists
{
    my $result = markdown_to_html("- [ ] unchecked task");
    is($result, "<div><li><input type=\"checkbox\" disabled /> unchecked task</li></div>", "Unchecked task");
    
    $result = markdown_to_html("- [x] checked task");
    is($result, "<div><li><input type=\"checkbox\" checked disabled /> checked task</li></div>", "Checked task");
}

# Test unordered lists
{
    my $result = markdown_to_html("- list item");
    is($result, "<div><ul><li>list item</li></ul></div>", "Unordered list with dash");
    
    $result = markdown_to_html("* list item");
    is($result, "<div><ul><li>list item</li></ul></div>", "Unordered list with asterisk");
}

# Test ordered lists
{
    my $result = markdown_to_html("1. first item");
    is($result, "<div><ol><li>first item</li></ol></div>", "Ordered list");
}

# Test tables
{
    my $markdown = "| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |";
    my $result = markdown_to_html($markdown);
    like($result, qr/<table>/, "Table contains table tag");
    like($result, qr/<th>Header 1<\/th>/, "Table header 1");
    like($result, qr/<td>Cell 1<\/td>/, "Table cell 1");
}

# Test options - disable features
{
    my $result = markdown_to_html("**bold**", { bold => 0, italic => 0, unordered_lists => 0 });
    is($result, "<div>**bold**</div>", "Bold disabled");
    
    $result = markdown_to_html("*italic*", { italic => 0, unordered_lists => 0 });
    is($result, "<div>*italic*</div>", "Italic disabled");
    
    $result = markdown_to_html("# Header", { headers => 0 });
    is($result, "<div># Header</div>", "Headers disabled");
}

# Test complex combinations
{
    my $result = markdown_to_html("**bold** and *italic* with `code`");
    is($result, "<div><strong>bold</strong> and <em>italic</em> with <code>code</code></div>", "Multiple formatting");
}

done_testing();
