use strict;
use warnings;
use Test::More tests => 11;
use Eshu;

# ── HTML patterns ──────────────────────────────────────────────────────────

# HTML5 login form
{
    my $in = <<'END';
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Login</title>
<link rel="stylesheet" href="/css/app.css">
</head>
<body>
<main class="auth-container">
<form method="POST" action="/login" class="login-form">
<h1>Sign in</h1>
<div class="field">
<label for="email">Email</label>
<input type="email" id="email" name="email" required autocomplete="email">
</div>
<div class="field">
<label for="password">Password</label>
<input type="password" id="password" name="password" required>
</div>
<button type="submit">Sign in</button>
<p><a href="/forgot">Forgot password?</a></p>
</form>
</main>
</body>
</html>
END
    my $exp = <<'END';
<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<title>Login</title>
		<link rel="stylesheet" href="/css/app.css">
	</head>
	<body>
		<main class="auth-container">
			<form method="POST" action="/login" class="login-form">
				<h1>Sign in</h1>
				<div class="field">
					<label for="email">Email</label>
					<input type="email" id="email" name="email" required autocomplete="email">
				</div>
				<div class="field">
					<label for="password">Password</label>
					<input type="password" id="password" name="password" required>
				</div>
				<button type="submit">Sign in</button>
				<p><a href="/forgot">Forgot password?</a></p>
			</form>
		</main>
	</body>
</html>
END
    is(Eshu->indent_html($in), $exp, 'HTML: login form with void elements and nested structure');
}

# Navigation component
{
    my $in = <<'END';
<nav class="site-nav" aria-label="Main navigation">
<div class="nav-brand">
<a href="/" class="logo"><img src="/img/logo.svg" alt="Home" width="120" height="40"></a>
</div>
<ul class="nav-links" role="list">
<li><a href="/about" class="nav-link">About</a></li>
<li class="has-dropdown">
<a href="/products" class="nav-link" aria-expanded="false">Products</a>
<ul class="dropdown" role="list">
<li><a href="/products/alpha">Alpha</a></li>
<li><a href="/products/beta">Beta</a></li>
</ul>
</li>
<li><a href="/contact" class="nav-link">Contact</a></li>
</ul>
<button class="nav-toggle" aria-controls="nav-links" aria-expanded="false">Menu</button>
</nav>
END
    my $exp = <<'END';
<nav class="site-nav" aria-label="Main navigation">
	<div class="nav-brand">
		<a href="/" class="logo"><img src="/img/logo.svg" alt="Home" width="120" height="40"></a>
	</div>
	<ul class="nav-links" role="list">
		<li><a href="/about" class="nav-link">About</a></li>
		<li class="has-dropdown">
			<a href="/products" class="nav-link" aria-expanded="false">Products</a>
			<ul class="dropdown" role="list">
				<li><a href="/products/alpha">Alpha</a></li>
				<li><a href="/products/beta">Beta</a></li>
			</ul>
		</li>
		<li><a href="/contact" class="nav-link">Contact</a></li>
	</ul>
	<button class="nav-toggle" aria-controls="nav-links" aria-expanded="false">Menu</button>
</nav>
END
    is(Eshu->indent_html($in), $exp, 'HTML: nested nav with dropdown and aria attributes');
}

# HTML table
{
    my $in = <<'END';
<table class="data-table" role="grid">
<thead>
<tr>
<th scope="col">Name</th>
<th scope="col">Email</th>
<th scope="col">Role</th>
<th scope="col"><span class="sr-only">Actions</span></th>
</tr>
</thead>
<tbody>
<tr>
<td>Alice</td>
<td>alice@example.com</td>
<td><span class="badge badge--admin">Admin</span></td>
<td><a href="/users/1/edit">Edit</a></td>
</tr>
</tbody>
</table>
END
    my $exp = <<'END';
<table class="data-table" role="grid">
	<thead>
		<tr>
			<th scope="col">Name</th>
			<th scope="col">Email</th>
			<th scope="col">Role</th>
			<th scope="col"><span class="sr-only">Actions</span></th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>Alice</td>
			<td>alice@example.com</td>
			<td><span class="badge badge--admin">Admin</span></td>
			<td><a href="/users/1/edit">Edit</a></td>
		</tr>
	</tbody>
</table>
END
    is(Eshu->indent_html($in), $exp, 'HTML: data table with thead/tbody and scope attributes');
}

# ── XML patterns ───────────────────────────────────────────────────────────

# Atom feed
{
    my $in = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<title>My Blog</title>
<subtitle>Thoughts on code</subtitle>
<link href="https://example.com/" rel="alternate"/>
<link href="https://example.com/feed.atom" rel="self"/>
<updated>2026-07-01T00:00:00Z</updated>
<id>https://example.com/</id>
<entry>
<title>Hello World</title>
<link href="https://example.com/posts/1" rel="alternate"/>
<id>https://example.com/posts/1</id>
<updated>2026-07-01T00:00:00Z</updated>
<summary>My first post</summary>
<author>
<name>Alice</name>
</author>
</entry>
</feed>
END
    my $exp = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
	<title>My Blog</title>
	<subtitle>Thoughts on code</subtitle>
	<link href="https://example.com/" rel="alternate"/>
	<link href="https://example.com/feed.atom" rel="self"/>
	<updated>2026-07-01T00:00:00Z</updated>
	<id>https://example.com/</id>
	<entry>
		<title>Hello World</title>
		<link href="https://example.com/posts/1" rel="alternate"/>
		<id>https://example.com/posts/1</id>
		<updated>2026-07-01T00:00:00Z</updated>
		<summary>My first post</summary>
		<author>
			<name>Alice</name>
		</author>
	</entry>
</feed>
END
    is(Eshu->indent_xml($in), $exp, 'XML: Atom feed with self-closing link elements');
}

# Maven pom.xml fragment
{
    my $in = <<'END';
<project xmlns="http://maven.apache.org/POM/4.0.0">
<modelVersion>4.0.0</modelVersion>
<groupId>com.example</groupId>
<artifactId>my-app</artifactId>
<version>1.0.0</version>
<dependencies>
<dependency>
<groupId>org.springframework</groupId>
<artifactId>spring-core</artifactId>
<version>6.0.0</version>
</dependency>
<dependency>
<groupId>junit</groupId>
<artifactId>junit</artifactId>
<version>4.13.2</version>
<scope>test</scope>
</dependency>
</dependencies>
<build>
<plugins>
<plugin>
<groupId>org.apache.maven.plugins</groupId>
<artifactId>maven-compiler-plugin</artifactId>
<configuration>
<source>17</source>
<target>17</target>
</configuration>
</plugin>
</plugins>
</build>
</project>
END
    my $exp = <<'END';
<project xmlns="http://maven.apache.org/POM/4.0.0">
	<modelVersion>4.0.0</modelVersion>
	<groupId>com.example</groupId>
	<artifactId>my-app</artifactId>
	<version>1.0.0</version>
	<dependencies>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-core</artifactId>
			<version>6.0.0</version>
		</dependency>
		<dependency>
			<groupId>junit</groupId>
			<artifactId>junit</artifactId>
			<version>4.13.2</version>
			<scope>test</scope>
		</dependency>
	</dependencies>
	<build>
		<plugins>
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-compiler-plugin</artifactId>
				<configuration>
					<source>17</source>
					<target>17</target>
				</configuration>
			</plugin>
		</plugins>
	</build>
</project>
END
    is(Eshu->indent_xml($in), $exp, 'XML: Maven pom.xml with deep plugin configuration');
}

# SVG icon
{
    my $in = <<'END';
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor">
<g stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<circle cx="12" cy="12" r="10"/>
<line x1="12" y1="8" x2="12" y2="12"/>
<line x1="12" y1="16" x2="12.01" y2="16"/>
</g>
</svg>
END
    my $exp = <<'END';
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor">
	<g stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
		<circle cx="12" cy="12" r="10"/>
		<line x1="12" y1="8" x2="12" y2="12"/>
		<line x1="12" y1="16" x2="12.01" y2="16"/>
	</g>
</svg>
END
    is(Eshu->indent_xml($in), $exp, 'XML: SVG icon with grouped self-closing elements');
}

# ── CSS patterns ──────────────────────────────────────────────────────────

# Design token system with media queries
{
    my $in = <<'END';
:root {
--font-size-base: 1rem;
--font-size-lg:   1.125rem;
--color-text:     #1a1a1a;
--color-bg:       #ffffff;
--spacing-sm:     0.5rem;
--spacing-md:     1rem;
--spacing-lg:     2rem;
--radius-sm:      0.25rem;
--radius-md:      0.5rem;
}

@media (prefers-color-scheme: dark) {
:root {
--color-text: #f5f5f5;
--color-bg:   #121212;
}
}

@media (min-width: 768px) {
:root {
--font-size-base: 1.0625rem;
--spacing-lg:     3rem;
}
}
END
    my $exp = <<'END';
:root {
	--font-size-base: 1rem;
	--font-size-lg:   1.125rem;
	--color-text:     #1a1a1a;
	--color-bg:       #ffffff;
	--spacing-sm:     0.5rem;
	--spacing-md:     1rem;
	--spacing-lg:     2rem;
	--radius-sm:      0.25rem;
	--radius-md:      0.5rem;
}

@media (prefers-color-scheme: dark) {
	:root {
		--color-text: #f5f5f5;
		--color-bg:   #121212;
	}
}

@media (min-width: 768px) {
	:root {
		--font-size-base: 1.0625rem;
		--spacing-lg:     3rem;
	}
}
END
    is(Eshu->indent_css($in), $exp, 'CSS: design token system with dark mode and breakpoint overrides');
}

# CSS Grid layout
{
    my $in = <<'END';
.page-layout {
display: grid;
grid-template-areas:
"header header"
"sidebar main"
"footer footer";
grid-template-columns: 240px 1fr;
grid-template-rows: auto 1fr auto;
min-height: 100vh;
}

.page-layout > header { grid-area: header; }
.page-layout > aside  { grid-area: sidebar; }
.page-layout > main   { grid-area: main; }
.page-layout > footer { grid-area: footer; }

@media (max-width: 767px) {
.page-layout {
grid-template-areas:
"header"
"main"
"sidebar"
"footer";
grid-template-columns: 1fr;
}
}
END
    my $exp = <<'END';
.page-layout {
	display: grid;
	grid-template-areas:
	"header header"
	"sidebar main"
	"footer footer";
	grid-template-columns: 240px 1fr;
	grid-template-rows: auto 1fr auto;
	min-height: 100vh;
}

.page-layout > header { grid-area: header; }
.page-layout > aside  { grid-area: sidebar; }
.page-layout > main   { grid-area: main; }
.page-layout > footer { grid-area: footer; }

@media (max-width: 767px) {
	.page-layout {
		grid-template-areas:
		"header"
		"main"
		"sidebar"
		"footer";
		grid-template-columns: 1fr;
	}
}
END
    is(Eshu->indent_css($in), $exp, 'CSS: grid-template-areas layout with responsive override');
}

# CSS animations and keyframes
{
    my $in = <<'END';
@keyframes spin {
0% {
transform: rotate(0deg);
}
100% {
transform: rotate(360deg);
}
}

@keyframes fade-in-up {
from {
opacity: 0;
transform: translateY(16px);
}
to {
opacity: 1;
transform: translateY(0);
}
}

.spinner {
animation: spin 1s linear infinite;
width: 2rem;
height: 2rem;
border: 3px solid var(--color-bg);
border-top-color: var(--color-primary);
border-radius: 50%;
}

.card-enter {
animation: fade-in-up 0.3s ease forwards;
}
END
    my $exp = <<'END';
@keyframes spin {
	0% {
		transform: rotate(0deg);
	}
	100% {
		transform: rotate(360deg);
	}
}

@keyframes fade-in-up {
	from {
		opacity: 0;
		transform: translateY(16px);
	}
	to {
		opacity: 1;
		transform: translateY(0);
	}
}

.spinner {
	animation: spin 1s linear infinite;
	width: 2rem;
	height: 2rem;
	border: 3px solid var(--color-bg);
	border-top-color: var(--color-primary);
	border-radius: 50%;
}

.card-enter {
	animation: fade-in-up 0.3s ease forwards;
}
END
    is(Eshu->indent_css($in), $exp, 'CSS: @keyframes animations with from/to and percentage steps');
}

# BEM component with modifier variants
{
    my $in = <<'END';
.btn {
display: inline-flex;
align-items: center;
gap: 0.5rem;
padding: 0.5rem 1rem;
border: 2px solid transparent;
border-radius: var(--radius-sm);
font-size: var(--font-size-base);
font-weight: 600;
cursor: pointer;
transition: background-color 0.15s, border-color 0.15s, color 0.15s;
}

.btn--primary {
background-color: var(--color-primary);
color: #fff;
}

.btn--primary:hover,
.btn--primary:focus-visible {
background-color: var(--color-primary-dark);
}

.btn--outline {
background-color: transparent;
border-color: var(--color-primary);
color: var(--color-primary);
}

.btn--outline:hover,
.btn--outline:focus-visible {
background-color: var(--color-primary);
color: #fff;
}

.btn--sm {
padding: 0.25rem 0.75rem;
font-size: 0.875rem;
}

.btn--lg {
padding: 0.75rem 1.5rem;
font-size: var(--font-size-lg);
}

.btn:disabled,
.btn[aria-disabled="true"] {
opacity: 0.5;
cursor: not-allowed;
pointer-events: none;
}
END
    my $exp = <<'END';
.btn {
	display: inline-flex;
	align-items: center;
	gap: 0.5rem;
	padding: 0.5rem 1rem;
	border: 2px solid transparent;
	border-radius: var(--radius-sm);
	font-size: var(--font-size-base);
	font-weight: 600;
	cursor: pointer;
	transition: background-color 0.15s, border-color 0.15s, color 0.15s;
}

.btn--primary {
	background-color: var(--color-primary);
	color: #fff;
}

.btn--primary:hover,
.btn--primary:focus-visible {
	background-color: var(--color-primary-dark);
}

.btn--outline {
	background-color: transparent;
	border-color: var(--color-primary);
	color: var(--color-primary);
}

.btn--outline:hover,
.btn--outline:focus-visible {
	background-color: var(--color-primary);
	color: #fff;
}

.btn--sm {
	padding: 0.25rem 0.75rem;
	font-size: 0.875rem;
}

.btn--lg {
	padding: 0.75rem 1.5rem;
	font-size: var(--font-size-lg);
}

.btn:disabled,
.btn[aria-disabled="true"] {
	opacity: 0.5;
	cursor: not-allowed;
	pointer-events: none;
}
END
    is(Eshu->indent_css($in), $exp, 'CSS: BEM button component with modifier variants and pseudo-selectors');
}

# Idempotency for web patterns
{
    my @cases = (
        ['html', "<div>\n<p>hello</p>\n<ul>\n<li>a</li>\n<li>b</li>\n</ul>\n</div>\n"],
        ['xml',  "<root>\n<a x='1'>\n<b/>\n</a>\n</root>\n"],
        ['css',  ".a {\ncolor: red;\n}\n.b {\ncolor: blue;\n}\n"],
    );
    my $ok = 1;
    for my $c (@cases) {
        my ($lang, $src) = @$c;
        my $once;
        if    ($lang eq 'html') { $once = Eshu->indent_html($src) }
        elsif ($lang eq 'xml')  { $once = Eshu->indent_xml($src)  }
        elsif ($lang eq 'css')  { $once = Eshu->indent_css($src)  }
        my $twice;
        if    ($lang eq 'html') { $twice = Eshu->indent_html($once) }
        elsif ($lang eq 'xml')  { $twice = Eshu->indent_xml($once)  }
        elsif ($lang eq 'css')  { $twice = Eshu->indent_css($once)  }
        $ok = 0 unless $once eq $twice;
    }
    ok($ok, 'Web: HTML/XML/CSS realworld snippets are idempotent');
}
