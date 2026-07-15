use strict;
use warnings;
use Test::More;
use Eshu;

sub h { Eshu->indent_html($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. basic page structure
{
	my $code = <<'END';
<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8">
		<title>My Page</title>
	</head>
	<body>
		<h1>Hello, World!</h1>
	</body>
</html>
END
	is(h($code), $code, 'HTML: basic page');
}

# 2. navigation menu
{
	my $code = <<'END';
<nav class="main-nav">
	<ul>
		<li><a href="/">Home</a></li>
		<li>
			<a href="/products">Products</a>
			<ul class="dropdown">
				<li><a href="/products/a">Product A</a></li>
				<li><a href="/products/b">Product B</a></li>
			</ul>
		</li>
		<li><a href="/contact">Contact</a></li>
	</ul>
</nav>
END
	is(h($code), $code, 'HTML: navigation with dropdown');
}

# 3. login form
{
	my $code = <<'END';
<form action="/login" method="post" class="login-form">
	<div class="field">
		<label for="username">Username</label>
		<input type="text" id="username" name="username" required>
	</div>
	<div class="field">
		<label for="password">Password</label>
		<input type="password" id="password" name="password" required>
	</div>
	<div class="field">
		<input type="checkbox" id="remember" name="remember">
		<label for="remember">Remember me</label>
	</div>
	<button type="submit">Log In</button>
</form>
END
	is(h($code), $code, 'HTML: login form');
}

# 4. data table
{
	my $code = <<'END';
<table class="data-table">
	<thead>
		<tr>
			<th scope="col">Name</th>
			<th scope="col">Age</th>
			<th scope="col">Email</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>Alice</td>
			<td>30</td>
			<td>alice@example.com</td>
		</tr>
		<tr>
			<td>Bob</td>
			<td>25</td>
			<td>bob@example.com</td>
		</tr>
	</tbody>
</table>
END
	is(h($code), $code, 'HTML: data table');
}

# 5. article with header
{
	my $code = <<'END';
<article>
	<header>
		<h1>Article Title</h1>
		<p class="meta">
			<time datetime="2024-01-01">January 1, 2024</time>
			by <a href="/author/jane">Jane Doe</a>
		</p>
	</header>
	<section>
		<p>First paragraph of content.</p>
		<p>Second paragraph with more detail.</p>
	</section>
	<footer>
		<p>Tags: <a href="/tag/tech">tech</a></p>
	</footer>
</article>
END
	is(h($code), $code, 'HTML: article with header/footer');
}

# 6. card grid
{
	my $code = <<'END';
<section class="card-grid">
	<div class="card">
		<img src="/img/a.jpg" alt="Card A">
		<div class="card-body">
			<h2>Card A</h2>
			<p>Description of card A.</p>
			<a href="/a" class="btn">Learn More</a>
		</div>
	</div>
	<div class="card">
		<img src="/img/b.jpg" alt="Card B">
		<div class="card-body">
			<h2>Card B</h2>
			<p>Description of card B.</p>
			<a href="/b" class="btn">Learn More</a>
		</div>
	</div>
</section>
END
	is(h($code), $code, 'HTML: card grid');
}

# 7. modal dialog
{
	my $code = <<'END';
<div class="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
	<div class="modal-backdrop"></div>
	<div class="modal-container">
		<header class="modal-header">
			<h2 id="modal-title">Confirm Action</h2>
			<button class="modal-close" aria-label="Close">&times;</button>
		</header>
		<div class="modal-body">
			<p>Are you sure you want to proceed?</p>
		</div>
		<footer class="modal-footer">
			<button type="button" class="btn btn-secondary">Cancel</button>
			<button type="button" class="btn btn-primary">Confirm</button>
		</footer>
	</div>
</div>
END
	is(h($code), $code, 'HTML: modal dialog');
}

# 8. responsive image with srcset
{
	my $code = <<'END';
<picture>
	<source media="(min-width: 1024px)" srcset="/img/hero-lg.webp">
	<source media="(min-width: 640px)" srcset="/img/hero-md.webp">
	<img src="/img/hero-sm.jpg" alt="Hero image" loading="lazy" width="800" height="400">
</picture>
END
	is(h($code), $code, 'HTML: responsive picture element');
}

# 9. video embed
{
	my $code = <<'END';
<figure>
	<video controls width="720" preload="metadata">
		<source src="/video/demo.mp4" type="video/mp4">
		<source src="/video/demo.webm" type="video/webm">
		<track src="/captions/demo.vtt" kind="captions" srclang="en" label="English">
		Your browser does not support the video element.
	</video>
	<figcaption>Demo video — click to play</figcaption>
</figure>
END
	is(h($code), $code, 'HTML: video with tracks');
}

# 10. details/summary
{
	my $code = <<'END';
<details>
	<summary>Click to expand</summary>
	<div class="details-content">
		<p>Hidden content revealed on click.</p>
		<ul>
			<li>Item one</li>
			<li>Item two</li>
		</ul>
	</div>
</details>
END
	is(h($code), $code, 'HTML: details/summary accordion');
}

# 11. search form
{
	my $code = <<'END';
<form role="search" action="/search" method="get">
	<div class="search-box">
		<input type="search" name="q" placeholder="Search..." aria-label="Search">
		<button type="submit" aria-label="Submit search">
			<svg aria-hidden="true"><use href="#icon-search"/></svg>
		</button>
	</div>
	<fieldset>
		<legend>Filter by type</legend>
		<label><input type="radio" name="type" value="all" checked> All</label>
		<label><input type="radio" name="type" value="docs"> Docs</label>
		<label><input type="radio" name="type" value="blog"> Blog</label>
	</fieldset>
</form>
END
	is(h($code), $code, 'HTML: search form with filters');
}

# 12. breadcrumb nav
{
	my $code = <<'END';
<nav aria-label="Breadcrumb">
	<ol class="breadcrumb">
		<li class="breadcrumb-item">
			<a href="/">Home</a>
		</li>
		<li class="breadcrumb-item">
			<a href="/products">Products</a>
		</li>
		<li class="breadcrumb-item" aria-current="page">Widget Pro</li>
	</ol>
</nav>
END
	is(h($code), $code, 'HTML: breadcrumb navigation');
}

# 13. pagination
{
	my $code = <<'END';
<nav aria-label="Pagination">
	<ul class="pagination">
		<li class="page-item disabled">
			<a class="page-link" href="#" aria-label="Previous">&laquo;</a>
		</li>
		<li class="page-item active" aria-current="page">
			<a class="page-link" href="/page/1">1</a>
		</li>
		<li class="page-item">
			<a class="page-link" href="/page/2">2</a>
		</li>
		<li class="page-item">
			<a class="page-link" href="/page/3">3</a>
		</li>
		<li class="page-item">
			<a class="page-link" href="/page/2" aria-label="Next">&raquo;</a>
		</li>
	</ul>
</nav>
END
	is(h($code), $code, 'HTML: pagination');
}

# 14. tabs widget
{
	my $code = <<'END';
<div class="tabs" role="tablist">
	<button role="tab" aria-selected="true" aria-controls="panel-1" id="tab-1">Overview</button>
	<button role="tab" aria-selected="false" aria-controls="panel-2" id="tab-2">Details</button>
	<button role="tab" aria-selected="false" aria-controls="panel-3" id="tab-3">Reviews</button>
</div>
<div id="panel-1" role="tabpanel" aria-labelledby="tab-1">
	<p>Overview content.</p>
</div>
<div id="panel-2" role="tabpanel" aria-labelledby="tab-2" hidden>
	<p>Details content.</p>
</div>
<div id="panel-3" role="tabpanel" aria-labelledby="tab-3" hidden>
	<p>Reviews content.</p>
</div>
END
	is(h($code), $code, 'HTML: ARIA tabs widget');
}

# 15. upload form
{
	my $code = <<'END';
<form action="/upload" method="post" enctype="multipart/form-data">
	<div class="upload-zone" id="drop-zone">
		<p>Drag files here or click to browse</p>
		<input type="file" name="files" multiple accept=".jpg,.png,.gif">
	</div>
	<div class="upload-options">
		<label>
			<input type="checkbox" name="resize" checked>
			Auto-resize images
		</label>
		<select name="quality">
			<option value="high">High quality</option>
			<option value="medium" selected>Medium</option>
			<option value="low">Low (smaller files)</option>
		</select>
	</div>
	<button type="submit">Upload</button>
</form>
END
	is(h($code), $code, 'HTML: file upload form');
}

# 16. alert/notification
{
	my $code = <<'END';
<div class="alert alert-success" role="alert" aria-live="polite">
	<svg class="alert-icon" aria-hidden="true">
		<use href="#icon-check"/>
	</svg>
	<div class="alert-content">
		<strong>Success!</strong>
		<p>Your changes have been saved.</p>
	</div>
	<button class="alert-dismiss" aria-label="Dismiss">&times;</button>
</div>
END
	is(h($code), $code, 'HTML: dismissable alert');
}

# 17. sidebar layout
{
	my $code = <<'END';
<div class="layout">
	<main class="main-content">
		<article>
			<h1>Main Article</h1>
			<p>Article content goes here.</p>
		</article>
	</main>
	<aside class="sidebar">
		<section class="widget">
			<h2>Related</h2>
			<ul>
				<li><a href="/related/1">Related Article 1</a></li>
				<li><a href="/related/2">Related Article 2</a></li>
			</ul>
		</section>
		<section class="widget">
			<h2>Tags</h2>
			<div class="tag-cloud">
				<a href="/tag/css">css</a>
				<a href="/tag/html">html</a>
				<a href="/tag/js">javascript</a>
			</div>
		</section>
	</aside>
</div>
END
	is(h($code), $code, 'HTML: sidebar layout');
}

# 18. product page
{
	my $code = <<'END';
<section class="product">
	<div class="product-gallery">
		<img src="/img/product-main.jpg" alt="Widget Pro" id="main-image">
		<div class="thumbnails">
			<img src="/img/product-1.jpg" alt="View 1">
			<img src="/img/product-2.jpg" alt="View 2">
			<img src="/img/product-3.jpg" alt="View 3">
		</div>
	</div>
	<div class="product-info">
		<h1>Widget Pro</h1>
		<p class="price">$99.99</p>
		<form action="/cart/add" method="post">
			<input type="hidden" name="product_id" value="42">
			<label for="qty">Quantity:</label>
			<input type="number" id="qty" name="quantity" value="1" min="1">
			<button type="submit">Add to Cart</button>
		</form>
	</div>
</section>
END
	is(h($code), $code, 'HTML: product page');
}

# 19. footer
{
	my $code = <<'END';
<footer class="site-footer">
	<div class="footer-content">
		<div class="footer-section">
			<h3>Company</h3>
			<ul>
				<li><a href="/about">About Us</a></li>
				<li><a href="/careers">Careers</a></li>
				<li><a href="/press">Press</a></li>
			</ul>
		</div>
		<div class="footer-section">
			<h3>Support</h3>
			<ul>
				<li><a href="/help">Help Center</a></li>
				<li><a href="/contact">Contact</a></li>
				<li><a href="/status">Status</a></li>
			</ul>
		</div>
		<div class="footer-section">
			<h3>Legal</h3>
			<ul>
				<li><a href="/privacy">Privacy</a></li>
				<li><a href="/terms">Terms</a></li>
			</ul>
		</div>
	</div>
	<div class="footer-bottom">
		<p>&copy; 2024 Example Corp. All rights reserved.</p>
	</div>
</footer>
END
	is(h($code), $code, 'HTML: site footer');
}

# 20. skeleton loader
{
	my $code = <<'END';
<div class="skeleton-card" aria-busy="true" aria-label="Loading...">
	<div class="skeleton skeleton-image"></div>
	<div class="skeleton-content">
		<div class="skeleton skeleton-title"></div>
		<div class="skeleton skeleton-text"></div>
		<div class="skeleton skeleton-text skeleton-short"></div>
	</div>
</div>
END
	is(h($code), $code, 'HTML: skeleton loader');
}

# 21. timeline
{
	my $code = <<'END';
<ol class="timeline">
	<li class="timeline-item">
		<time datetime="2024-01">January 2024</time>
		<p>Project kicked off.</p>
	</li>
	<li class="timeline-item">
		<time datetime="2024-03">March 2024</time>
		<p>Beta released to early users.</p>
	</li>
	<li class="timeline-item">
		<time datetime="2024-06">June 2024</time>
		<p>General availability launch.</p>
	</li>
</ol>
END
	is(h($code), $code, 'HTML: timeline list');
}

# 22. icon sprite usage
{
	my $code = <<'END';
<div class="actions">
	<button type="button" aria-label="Edit">
		<svg aria-hidden="true" focusable="false">
			<use href="/icons.svg#edit"/>
		</svg>
	</button>
	<button type="button" aria-label="Delete">
		<svg aria-hidden="true" focusable="false">
			<use href="/icons.svg#trash"/>
		</svg>
	</button>
</div>
END
	is(h($code), $code, 'HTML: SVG icon sprite usage');
}

# 23. progress indicator
{
	my $code = <<'END';
<div class="progress-steps">
	<div class="step completed">
		<span class="step-number">1</span>
		<span class="step-label">Account</span>
	</div>
	<div class="step active">
		<span class="step-number">2</span>
		<span class="step-label">Details</span>
	</div>
	<div class="step">
		<span class="step-number">3</span>
		<span class="step-label">Confirm</span>
	</div>
</div>
END
	is(h($code), $code, 'HTML: progress steps indicator');
}

# 24. meta tags
{
	my $code = <<'END';
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<meta name="description" content="Example website description">
	<meta property="og:title" content="Page Title">
	<meta property="og:description" content="Page description for sharing">
	<meta property="og:image" content="https://example.com/og.jpg">
	<meta name="twitter:card" content="summary_large_image">
	<link rel="canonical" href="https://example.com/page">
	<title>Page Title | Site Name</title>
</head>
END
	is(h($code), $code, 'HTML: head with meta tags');
}

# 25. definition list
{
	my $code = <<'END';
<dl class="glossary">
	<dt>HTML</dt>
	<dd>HyperText Markup Language — the structure of web pages.</dd>
	<dt>CSS</dt>
	<dd>Cascading Style Sheets — the presentation of web pages.</dd>
	<dt>JavaScript</dt>
	<dd>A programming language for interactive web features.</dd>
</dl>
END
	is(h($code), $code, 'HTML: definition list');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
	my $in = <<'END';
<div>
<p>Hello</p>
<p>World</p>
</div>
END
	my $exp = <<'END';
<div>
	<p>Hello</p>
	<p>World</p>
</div>
END
	is(h($in), $exp, 'HTML: unindented div/p normalised');
}

# 27
{
	my $in = <<'END';
<ul>
<li>Apple</li>
<li>Banana</li>
<li>Cherry</li>
</ul>
END
	my $exp = <<'END';
<ul>
	<li>Apple</li>
	<li>Banana</li>
	<li>Cherry</li>
</ul>
END
	is(h($in), $exp, 'HTML: unindented list normalised');
}

# 28
{
	my $in = <<'END';
<table>
<tr>
<th>Name</th>
<th>Score</th>
</tr>
<tr>
<td>Alice</td>
<td>95</td>
</tr>
</table>
END
	my $exp = <<'END';
<table>
	<tr>
		<th>Name</th>
		<th>Score</th>
	</tr>
	<tr>
		<td>Alice</td>
		<td>95</td>
	</tr>
</table>
END
	is(h($in), $exp, 'HTML: unindented table normalised');
}

# 29
{
	my $in = <<'END';
<section>
<h2>FAQ</h2>
<details>
<summary>What is this?</summary>
<p>A question and answer section.</p>
</details>
<details>
<summary>How does it work?</summary>
<p>Click to expand for more info.</p>
</details>
</section>
END
	my $exp = <<'END';
<section>
	<h2>FAQ</h2>
	<details>
		<summary>What is this?</summary>
		<p>A question and answer section.</p>
	</details>
	<details>
		<summary>How does it work?</summary>
		<p>Click to expand for more info.</p>
	</details>
</section>
END
	is(h($in), $exp, 'HTML: unindented FAQ section normalised');
}

# 30
{
	my $in = <<'END';
<form>
<label for="name">Name</label>
<input type="text" id="name" name="name">
<label for="msg">Message</label>
<textarea id="msg" name="message" rows="5"></textarea>
<button type="submit">Send</button>
</form>
END
	my $exp = <<'END';
<form>
	<label for="name">Name</label>
	<input type="text" id="name" name="name">
	<label for="msg">Message</label>
	<textarea id="msg" name="message" rows="5"></textarea>
	<button type="submit">Send</button>
</form>
END
	is(h($in), $exp, 'HTML: unindented contact form normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
	"<html>\n<head>\n<title>T</title>\n<link rel=\"stylesheet\" href=\"a.css\">\n</head>\n<body>\n<div id=\"app\">\n<header>\n<nav>\n<a href=\"/\">Home</a>\n</nav>\n</header>\n<main>\n<p>Content</p>\n</main>\n</div>\n</body>\n</html>\n",
	"<div class=\"dropdown\">\n<button>Menu</button>\n<ul>\n<li><a href=\"/a\">A</a></li>\n<li>\n<a href=\"/b\">B</a>\n<ul>\n<li><a href=\"/b1\">B1</a></li>\n<li><a href=\"/b2\">B2</a></li>\n</ul>\n</li>\n</ul>\n</div>\n",
	"<article>\n<header>\n<h1>Title</h1>\n<p>By <a href=\"/a\">Author</a></p>\n</header>\n<section>\n<h2>S1</h2>\n<p>Text</p>\n</section>\n<section>\n<h2>S2</h2>\n<p>Text</p>\n</section>\n<footer>\n<p>Tags</p>\n</footer>\n</article>\n",
	"<div class=\"wizard\">\n<nav>\n<button data-step=\"1\">Step 1</button>\n<button data-step=\"2\">Step 2</button>\n<button data-step=\"3\">Step 3</button>\n</nav>\n<div data-panel=\"1\">\n<h2>Info</h2>\n<input type=\"text\" name=\"name\">\n</div>\n<div data-panel=\"2\" hidden>\n<h2>Details</h2>\n</div>\n<div data-panel=\"3\" hidden>\n<h2>Review</h2>\n</div>\n</div>\n",
	"<main>\n<h1>Dashboard</h1>\n<div class=\"stats\">\n<div class=\"stat-card\">\n<h2>Users</h2>\n<p class=\"number\">1,234</p>\n</div>\n<div class=\"stat-card\">\n<h2>Revenue</h2>\n<p class=\"number\">\$56,789</p>\n</div>\n</div>\n</main>\n",
	"<header role=\"banner\">\n<a href=\"/\" class=\"logo\">\n<img src=\"/logo.svg\" alt=\"Site Logo\" width=\"120\" height=\"40\">\n</a>\n<nav aria-label=\"Main\">\n<ul>\n<li><a href=\"/features\" aria-current=\"page\">Features</a></li>\n<li><a href=\"/pricing\">Pricing</a></li>\n<li><a href=\"/docs\">Docs</a></li>\n</ul>\n</nav>\n<a href=\"/signup\" class=\"cta\">Get Started</a>\n</header>\n",
	"<ol class=\"steps\">\n<li>\n<h3>Install</h3>\n<code>npm install widget</code>\n</li>\n<li>\n<h3>Import</h3>\n<code>import Widget from 'widget'</code>\n</li>\n<li>\n<h3>Use</h3>\n<code>&lt;Widget /&gt;</code>\n</li>\n</ol>\n",
	"<div class=\"accordion\">\n<div class=\"accordion-item\">\n<button class=\"accordion-header\">Section 1</button>\n<div class=\"accordion-body\">\n<p>Content 1</p>\n</div>\n</div>\n<div class=\"accordion-item\">\n<button class=\"accordion-header\">Section 2</button>\n<div class=\"accordion-body\" hidden>\n<p>Content 2</p>\n</div>\n</div>\n</div>\n",
	"<aside class=\"sidebar\">\n<section>\n<h2>Recent</h2>\n<ul>\n<li><a href=\"/p/1\">Post 1</a></li>\n<li><a href=\"/p/2\">Post 2</a></li>\n<li><a href=\"/p/3\">Post 3</a></li>\n</ul>\n</section>\n<section>\n<h2>Popular</h2>\n<ul>\n<li><a href=\"/p/a\">Article A</a></li>\n<li><a href=\"/p/b\">Article B</a></li>\n</ul>\n</section>\n</aside>\n",
	"<div class=\"toast\" role=\"alert\" aria-live=\"assertive\">\n<div class=\"toast-header\">\n<strong>Notification</strong>\n<button type=\"button\" class=\"close\" aria-label=\"Close\">X</button>\n</div>\n<div class=\"toast-body\">\nYour file has been uploaded successfully.\n</div>\n</div>\n",
	"<form class=\"settings\">\n<fieldset>\n<legend>Notifications</legend>\n<label><input type=\"checkbox\" name=\"email\" checked> Email</label>\n<label><input type=\"checkbox\" name=\"sms\"> SMS</label>\n<label><input type=\"checkbox\" name=\"push\" checked> Push</label>\n</fieldset>\n<fieldset>\n<legend>Privacy</legend>\n<label><input type=\"radio\" name=\"visibility\" value=\"public\" checked> Public</label>\n<label><input type=\"radio\" name=\"visibility\" value=\"private\"> Private</label>\n</fieldset>\n<button type=\"submit\">Save</button>\n</form>\n",
	"<div class=\"chat\">\n<div class=\"messages\">\n<div class=\"message sent\">\n<p>Hello!</p>\n<time>10:00</time>\n</div>\n<div class=\"message received\">\n<p>Hi there!</p>\n<time>10:01</time>\n</div>\n</div>\n<form class=\"compose\">\n<input type=\"text\" placeholder=\"Type a message...\">\n<button type=\"submit\">Send</button>\n</form>\n</div>\n",
	"<div class=\"kanban\">\n<div class=\"column\" data-status=\"todo\">\n<h2>To Do</h2>\n<div class=\"card\" draggable=\"true\">Task A</div>\n<div class=\"card\" draggable=\"true\">Task B</div>\n</div>\n<div class=\"column\" data-status=\"doing\">\n<h2>In Progress</h2>\n<div class=\"card\" draggable=\"true\">Task C</div>\n</div>\n<div class=\"column\" data-status=\"done\">\n<h2>Done</h2>\n<div class=\"card\">Task D</div>\n</div>\n</div>\n",
	"<iframe\n  src=\"https://www.youtube.com/embed/abc123\"\n  title=\"Video\"\n  frameborder=\"0\"\n  allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope\"\n  allowfullscreen>\n</iframe>\n",
	"<figure class=\"code-example\">\n<pre><code class=\"language-js\">const x = 1;</code></pre>\n<figcaption>Example JavaScript</figcaption>\n</figure>\n",
) {
	my $once = h($snippet);
	is(h($once), $once, 'HTML: snippet idempotent');
}

done_testing;
