use strict;
use warnings;
use Test::More;
use Eshu;

sub cs { Eshu->indent_css($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. basic rule
{
	my $code = <<'END';
body {
	margin: 0;
	padding: 0;
	font-family: system-ui, sans-serif;
	background: #fff;
	color: #333;
}
END
	is(cs($code), $code, 'CSS: basic body rule');
}

# 2. nested selectors
{
	my $code = <<'END';
.card {
	border: 1px solid #ddd;
	border-radius: 8px;
	padding: 16px;
	box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.card-title {
	font-size: 1.25rem;
	font-weight: 600;
	margin-bottom: 8px;
}

.card-body {
	color: #555;
	line-height: 1.6;
}
END
	is(cs($code), $code, 'CSS: card component rules');
}

# 3. custom properties
{
	my $code = <<'END';
:root {
	--color-primary: #0070f3;
	--color-secondary: #7928ca;
	--color-success: #0a7a4d;
	--color-error: #e00;
	--spacing-unit: 8px;
	--border-radius: 4px;
	--font-size-base: 16px;
	--font-size-sm: 0.875rem;
	--font-size-lg: 1.125rem;
}
END
	is(cs($code), $code, 'CSS: custom properties (design tokens)');
}

# 4. flexbox layout
{
	my $code = <<'END';
.flex-row {
	display: flex;
	flex-direction: row;
	align-items: center;
	gap: 16px;
}

.flex-col {
	display: flex;
	flex-direction: column;
	justify-content: space-between;
}

.flex-grow {
	flex: 1 1 auto;
	min-width: 0;
}
END
	is(cs($code), $code, 'CSS: flexbox utilities');
}

# 5. CSS Grid layout
{
	my $code = <<'END';
.grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
	grid-gap: 24px;
	align-items: start;
}

.grid-header {
	grid-column: 1 / -1;
}

.grid-sidebar {
	grid-column: 1;
	grid-row: 2 / span 3;
}
END
	is(cs($code), $code, 'CSS: grid layout');
}

# 6. media queries
{
	my $code = <<'END';
.container {
	width: 100%;
	max-width: 1200px;
	margin: 0 auto;
	padding: 0 16px;
}

@media (min-width: 640px) {
	.container {
		padding: 0 24px;
	}
}

@media (min-width: 1024px) {
	.container {
		padding: 0 32px;
	}
}
END
	is(cs($code), $code, 'CSS: responsive container with media queries');
}

# 7. keyframe animation
{
	my $code = <<'END';
@keyframes fadeIn {
	from {
		opacity: 0;
		transform: translateY(-8px);
	}
	to {
		opacity: 1;
		transform: translateY(0);
	}
}

.fade-in {
	animation: fadeIn 0.3s ease-out forwards;
}
END
	is(cs($code), $code, 'CSS: keyframe animation');
}

# 8. spinner animation
{
	my $code = <<'END';
@keyframes spin {
	0% {
		transform: rotate(0deg);
	}
	100% {
		transform: rotate(360deg);
	}
}

.spinner {
	width: 24px;
	height: 24px;
	border: 3px solid #e0e0e0;
	border-top-color: var(--color-primary);
	border-radius: 50%;
	animation: spin 0.8s linear infinite;
}
END
	is(cs($code), $code, 'CSS: spinner animation');
}

# 9. button variants
{
	my $code = <<'END';
.btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 8px 16px;
	border: none;
	border-radius: var(--border-radius);
	font-size: var(--font-size-base);
	cursor: pointer;
	transition: background 0.2s, box-shadow 0.2s;
}

.btn-primary {
	background: var(--color-primary);
	color: #fff;
}

.btn-primary:hover {
	background: #005cc5;
	box-shadow: 0 4px 12px rgba(0,112,243,0.4);
}

.btn-secondary {
	background: transparent;
	color: var(--color-primary);
	border: 1px solid var(--color-primary);
}
END
	is(cs($code), $code, 'CSS: button variants');
}

# 10. form styles
{
	my $code = <<'END';
.form-group {
	display: flex;
	flex-direction: column;
	gap: 4px;
	margin-bottom: 16px;
}

.form-label {
	font-size: var(--font-size-sm);
	font-weight: 500;
	color: #555;
}

.form-input {
	padding: 8px 12px;
	border: 1px solid #ccc;
	border-radius: var(--border-radius);
	font-size: var(--font-size-base);
	transition: border-color 0.2s, box-shadow 0.2s;
}

.form-input:focus {
	outline: none;
	border-color: var(--color-primary);
	box-shadow: 0 0 0 3px rgba(0,112,243,0.2);
}
END
	is(cs($code), $code, 'CSS: form control styles');
}

# 11. typography scale
{
	my $code = <<'END';
h1, h2, h3, h4, h5, h6 {
	font-weight: 600;
	line-height: 1.25;
	margin-top: 0;
}

h1 { font-size: 2.25rem; }
h2 { font-size: 1.75rem; }
h3 { font-size: 1.375rem; }
h4 { font-size: 1.125rem; }
h5 { font-size: 1rem; }
h6 { font-size: 0.875rem; }

p {
	margin-top: 0;
	margin-bottom: 1rem;
	line-height: 1.7;
}
END
	is(cs($code), $code, 'CSS: typography scale');
}

# 12. pseudo-elements
{
	my $code = <<'END';
.required::after {
	content: " *";
	color: var(--color-error);
}

.external-link::after {
	content: " \2197";
	font-size: 0.75em;
}

.list-item::before {
	content: "";
	display: inline-block;
	width: 6px;
	height: 6px;
	background: var(--color-primary);
	border-radius: 50%;
	margin-right: 8px;
	vertical-align: middle;
}
END
	is(cs($code), $code, 'CSS: pseudo-elements');
}

# 13. dark mode
{
	my $code = <<'END';
@media (prefers-color-scheme: dark) {
	:root {
		--color-bg: #0d1117;
		--color-surface: #161b22;
		--color-text: #e6edf3;
		--color-text-muted: #8d96a0;
		--color-border: #30363d;
	}

	body {
		background: var(--color-bg);
		color: var(--color-text);
	}
}
END
	is(cs($code), $code, 'CSS: dark mode via prefers-color-scheme');
}

# 14. table styles
{
	my $code = <<'END';
.table {
	width: 100%;
	border-collapse: collapse;
	font-size: var(--font-size-sm);
}

.table th {
	text-align: left;
	padding: 10px 12px;
	background: #f8f9fa;
	border-bottom: 2px solid #dee2e6;
	font-weight: 600;
}

.table td {
	padding: 10px 12px;
	border-bottom: 1px solid #dee2e6;
}

.table tr:last-child td {
	border-bottom: none;
}
END
	is(cs($code), $code, 'CSS: table styles');
}

# 15. tooltip
{
	my $code = <<'END';
[data-tooltip] {
	position: relative;
}

[data-tooltip]::after {
	content: attr(data-tooltip);
	position: absolute;
	bottom: calc(100% + 6px);
	left: 50%;
	transform: translateX(-50%);
	padding: 4px 8px;
	background: #333;
	color: #fff;
	font-size: 0.75rem;
	border-radius: 4px;
	white-space: nowrap;
	pointer-events: none;
	opacity: 0;
	transition: opacity 0.2s;
}

[data-tooltip]:hover::after {
	opacity: 1;
}
END
	is(cs($code), $code, 'CSS: tooltip with pseudo-element');
}

# 16. card hover effect
{
	my $code = <<'END';
.hover-card {
	transform: translateY(0);
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.hover-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 12px 24px rgba(0,0,0,0.15);
}
END
	is(cs($code), $code, 'CSS: hover lift effect');
}

# 17. @layer rule
{
	my $code = <<'END';
@layer base {
	*, *::before, *::after {
		box-sizing: border-box;
	}

	html {
		font-size: 16px;
		scroll-behavior: smooth;
	}
}

@layer components {
	.btn {
		display: inline-block;
		padding: 8px 16px;
	}
}
END
	is(cs($code), $code, 'CSS: @layer cascade layers');
}

# 18. container queries
{
	my $code = <<'END';
.sidebar {
	container-type: inline-size;
}

@container (min-width: 300px) {
	.widget {
		display: flex;
		gap: 12px;
	}
}

@container (min-width: 600px) {
	.widget {
		grid-template-columns: 1fr 2fr;
	}
}
END
	is(cs($code), $code, 'CSS: container queries');
}

# 19. scrollbar styling
{
	my $code = <<'END';
.scrollable {
	overflow-y: auto;
	scrollbar-width: thin;
	scrollbar-color: #888 transparent;
}

.scrollable::-webkit-scrollbar {
	width: 6px;
}

.scrollable::-webkit-scrollbar-track {
	background: transparent;
}

.scrollable::-webkit-scrollbar-thumb {
	background: #888;
	border-radius: 3px;
}
END
	is(cs($code), $code, 'CSS: scrollbar styling');
}

# 20. focus-visible
{
	my $code = <<'END';
:focus {
	outline: none;
}

:focus-visible {
	outline: 2px solid var(--color-primary);
	outline-offset: 2px;
}
END
	is(cs($code), $code, 'CSS: focus-visible ring');
}

# 21. CSS reset / normalise
{
	my $code = <<'END';
*,
*::before,
*::after {
	box-sizing: border-box;
}

body {
	min-height: 100vh;
	text-rendering: optimizeSpeed;
	line-height: 1.5;
}

img,
picture,
video,
canvas,
svg {
	display: block;
	max-width: 100%;
}

input,
button,
textarea,
select {
	font: inherit;
}
END
	is(cs($code), $code, 'CSS: modern reset');
}

# 22. skeleton loader
{
	my $code = <<'END';
@keyframes skeleton-pulse {
	0% {
		background-position: -200% 0;
	}
	100% {
		background-position: 200% 0;
	}
}

.skeleton {
	background: linear-gradient(90deg, #e0e0e0 25%, #f5f5f5 50%, #e0e0e0 75%);
	background-size: 200% 100%;
	animation: skeleton-pulse 1.5s ease-in-out infinite;
	border-radius: 4px;
}
END
	is(cs($code), $code, 'CSS: skeleton loader pulse');
}

# 23. aspect ratio box
{
	my $code = <<'END';
.video-wrapper {
	position: relative;
	width: 100%;
	aspect-ratio: 16 / 9;
	overflow: hidden;
	border-radius: 8px;
}

.video-wrapper iframe {
	position: absolute;
	inset: 0;
	width: 100%;
	height: 100%;
}
END
	is(cs($code), $code, 'CSS: aspect-ratio video wrapper');
}

# 24. print styles
{
	my $code = <<'END';
@media print {
	.no-print,
	nav,
	.sidebar,
	.ads {
		display: none !important;
	}

	body {
		font-size: 12pt;
		color: #000;
	}

	a[href]::after {
		content: " (" attr(href) ")";
		font-size: 0.8em;
	}
}
END
	is(cs($code), $code, 'CSS: print styles');
}

# 25. accent-color and color-scheme
{
	my $code = <<'END';
:root {
	accent-color: var(--color-primary);
	color-scheme: light dark;
}

input[type="checkbox"],
input[type="radio"],
input[type="range"] {
	accent-color: inherit;
}
END
	is(cs($code), $code, 'CSS: accent-color and color-scheme');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
	my $in = <<'END';
.alert {
background: #ffe;
border: 1px solid #cc0;
padding: 12px 16px;
border-radius: 4px;
}
END
	my $exp = <<'END';
.alert {
	background: #ffe;
	border: 1px solid #cc0;
	padding: 12px 16px;
	border-radius: 4px;
}
END
	is(cs($in), $exp, 'CSS: unindented alert rule normalised');
}

# 27
{
	my $in = <<'END';
@media (max-width: 768px) {
.nav {
display: none;
}
.hamburger {
display: block;
}
}
END
	my $exp = <<'END';
@media (max-width: 768px) {
	.nav {
		display: none;
	}
	.hamburger {
		display: block;
	}
}
END
	is(cs($in), $exp, 'CSS: unindented media query normalised');
}

# 28
{
	my $in = <<'END';
@keyframes bounce {
0%, 100% {
transform: translateY(0);
}
50% {
transform: translateY(-20px);
}
}
END
	my $exp = <<'END';
@keyframes bounce {
	0%, 100% {
		transform: translateY(0);
	}
	50% {
		transform: translateY(-20px);
	}
}
END
	is(cs($in), $exp, 'CSS: unindented keyframes normalised');
}

# 29
{
	my $in = <<'END';
.modal {
position: fixed;
inset: 0;
display: flex;
align-items: center;
justify-content: center;
background: rgba(0,0,0,0.5);
}
.modal-box {
background: #fff;
padding: 24px;
border-radius: 8px;
max-width: 480px;
width: 100%;
}
END
	my $exp = <<'END';
.modal {
	position: fixed;
	inset: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	background: rgba(0,0,0,0.5);
}
.modal-box {
	background: #fff;
	padding: 24px;
	border-radius: 8px;
	max-width: 480px;
	width: 100%;
}
END
	is(cs($in), $exp, 'CSS: unindented modal normalised');
}

# 30
{
	my $in = <<'END';
:root {
--red: 255;
--green: 255;
--blue: 255;
}
END
	my $exp = <<'END';
:root {
	--red: 255;
	--green: 255;
	--blue: 255;
}
END
	is(cs($in), $exp, 'CSS: unindented custom properties normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
	".wrapper{max-width:1200px;margin:0 auto;padding:0 16px}\n.wrapper--full{max-width:100%}\n.wrapper--narrow{max-width:640px}\n",
	".sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}\n",
	"\@supports (display:grid) {\n.layout{display:grid;grid-template-columns:repeat(12,1fr);gap:24px}\n}\n",
	".badge{display:inline-flex;align-items:center;padding:2px 8px;border-radius:9999px;font-size:0.75rem}\n.badge-primary{background:var(--color-primary);color:#fff}\n.badge-success{background:var(--color-success);color:#fff}\n.badge-error{background:var(--color-error);color:#fff}\n",
	"\@layer utilities{\n.mt-1{margin-top:4px}\n.mt-2{margin-top:8px}\n.mt-4{margin-top:16px}\n.mt-8{margin-top:32px}\n}\n",
	"a{color:var(--color-primary);text-decoration:underline;text-underline-offset:2px}\na:hover{color:#005cc5}\na:visited{color:#7928ca}\na:focus-visible{outline:2px solid var(--color-primary);outline-offset:2px}\n",
	".visually-hidden:not(:focus):not(:focus-within){clip:rect(0 0 0 0);clip-path:inset(50%);height:1px;overflow:hidden;position:absolute;white-space:nowrap;width:1px}\n",
	":root{--ease-out:cubic-bezier(0,0,0.2,1);--ease-in:cubic-bezier(0.4,0,1,1);--ease-in-out:cubic-bezier(0.4,0,0.2,1)}\n.transition-all{transition:all 200ms var(--ease-in-out)}\n",
	"\@media(hover:hover){\n.hover-highlight:hover{background:rgba(0,0,0,0.05)}\n}\n\@media(hover:none){\n.hover-highlight:active{background:rgba(0,0,0,0.05)}\n}\n",
	"ul.reset,ol.reset{list-style:none;margin:0;padding:0}\nul.reset li,ol.reset li{margin:0;padding:0}\n",
	".grid-cols-1{grid-template-columns:repeat(1,minmax(0,1fr))}\n.grid-cols-2{grid-template-columns:repeat(2,minmax(0,1fr))}\n.grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}\n.grid-cols-4{grid-template-columns:repeat(4,minmax(0,1fr))}\n",
	".truncate{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\n.line-clamp-2{display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}\n.line-clamp-3{display:-webkit-box;-webkit-line-clamp:3;-webkit-box-orient:vertical;overflow:hidden}\n",
	"img.lazy{opacity:0;transition:opacity 0.3s}\nimg.lazy.loaded{opacity:1}\n.placeholder{background:linear-gradient(90deg,#e0e0e0 25%,#f0f0f0 50%,#e0e0e0 75%);background-size:200%}\n",
	".split{display:flex;gap:1rem}\n.split>*{flex:1}\n.split--70-30>:first-child{flex:7}\n.split--70-30>:last-child{flex:3}\n",
	"fieldset{border:0;margin:0;padding:0}\nlegend{font-weight:600;margin-bottom:8px}\nselect{appearance:none;background-image:url(\"data:image/svg+xml,...\");background-repeat:no-repeat;background-position:right 8px center}\n",
) {
	my $once = cs($snippet);
	is(cs($once), $once, 'CSS: snippet idempotent');
}

done_testing;
