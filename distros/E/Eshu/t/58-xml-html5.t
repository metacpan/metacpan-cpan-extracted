use strict;
use warnings;
use Test::More;
use Eshu;

# HTML5 data-* attributes
{
	my $input = <<'END';
<div data-user-id="42" data-role="admin">
<span data-label="name">Alice</span>
</div>
END

	my $expected = <<'END';
<div data-user-id="42" data-role="admin">
	<span data-label="name">Alice</span>
</div>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'HTML5 data-* attributes');
}

# SVG element structure
{
	my $input = <<'END';
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
<circle cx="50" cy="50" r="40" fill="blue"/>
<rect x="10" y="10" width="80" height="80" fill="none" stroke="red"/>
<text x="50" y="55" text-anchor="middle">Hello</text>
</svg>
END

	my $expected = <<'END';
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
	<circle cx="50" cy="50" r="40" fill="blue"/>
	<rect x="10" y="10" width="80" height="80" fill="none" stroke="red"/>
	<text x="50" y="55" text-anchor="middle">Hello</text>
</svg>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'SVG element structure');
}

# Nested HTML table
{
	my $input = <<'END';
<table>
<thead>
<tr>
<th>Name</th>
<th>Age</th>
</tr>
</thead>
<tbody>
<tr>
<td>Alice</td>
<td>30</td>
</tr>
</tbody>
</table>
END

	my $expected = <<'END';
<table>
	<thead>
		<tr>
			<th>Name</th>
			<th>Age</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>Alice</td>
			<td>30</td>
		</tr>
	</tbody>
</table>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'nested HTML table structure');
}

# figure/figcaption
{
	my $input = <<'END';
<figure>
<img src="photo.jpg" alt="A photo"/>
<figcaption>
<p>Photo description</p>
</figcaption>
</figure>
END

	my $expected = <<'END';
<figure>
	<img src="photo.jpg" alt="A photo"/>
	<figcaption>
		<p>Photo description</p>
	</figcaption>
</figure>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'figure with figcaption');
}

# nav with nested ul/li
{
	my $input = <<'END';
<nav aria-label="Main navigation">
<ul>
<li><a href="/">Home</a></li>
<li>
<a href="/products">Products</a>
<ul>
<li><a href="/products/a">Item A</a></li>
<li><a href="/products/b">Item B</a></li>
</ul>
</li>
</ul>
</nav>
END

	my $expected = <<'END';
<nav aria-label="Main navigation">
	<ul>
		<li><a href="/">Home</a></li>
		<li>
			<a href="/products">Products</a>
			<ul>
				<li><a href="/products/a">Item A</a></li>
				<li><a href="/products/b">Item B</a></li>
			</ul>
		</li>
	</ul>
</nav>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'nav with nested ul/li dropdown');
}

done_testing();
