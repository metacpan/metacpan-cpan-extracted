# facialharmonyai-site-kit

URL helpers and metadata utilities for [FacialHarmonyAI](https://facialharmonyai.com) — an AI-powered facial analysis and coaching platform.

## What is FacialHarmonyAI?

FacialHarmonyAI provides AI-driven facial symmetry analysis, aesthetic scoring, and personalized improvement coaching. Upload a photo and get instant feedback on facial harmony, proportions, and enhancement suggestions.

## Features

- Build URLs for analysis pages, pricing, features, FAQ, blog, and dashboard
- Validate and normalize facial analysis report IDs
- Multi-ecosystem: available on npm, PyPI, crates.io, Go, RubyGems, pub.dev, Hex.pm, Clojars, and Docker Hub
- New package ecosystem helpers prepared for JSR, Maven Central/javadoc.io, NuGet, CocoaPods, LuaRocks, CPAN/MetaCPAN, Hackage, Chocolatey, GitHub Packages, and GitLab Package Registry

## Installation

```bash
npm install facialharmonyai-site-kit
pip install facialharmonyai-site-kit
cargo add facialharmonyai-site-kit
go get github.com/bbwdadfg/facialharmonyai-site-kit
gem install facialharmonyai-site-kit
dart pub add facialharmonyai_site_kit
mix hex.install facialharmonyai_site_kit
```

Additional ecosystem manifests and helper sources are included for trial publishing on newer channels:

- JSR: `jsr.json`, `mod.ts`
- CPAN/MetaCPAN: `Makefile.PL`, `lib/FacialHarmonyAI/SiteKit.pm`
- Maven Central/javadoc.io: `src/main/java/com/facialharmonyai/sitekit/SiteKit.java`
- NuGet: `nuget/FacialHarmonyAI.SiteKit/FacialHarmonyAI.SiteKit.csproj`
- CocoaPods: `FacialHarmonyAISiteKit.podspec`
- LuaRocks: `facialharmonyai-site-kit-0.1.0-1.rockspec`
- Hackage: `facialharmonyai-site-kit.cabal`
- Chocolatey: `chocolatey/facialharmonyai-site-kit.nuspec`

## Usage

```js
// JavaScript / Node.js
const { analysisUrl, pricingUrl, reportUrl } = require('facialharmonyai-site-kit');

console.log(analysisUrl());
// => "https://facialharmonyai.com/analyze"

console.log(pricingUrl());
// => "https://facialharmonyai.com/#pricing"

console.log(reportUrl('abc123'));
// => "https://facialharmonyai.com/report/abc123"
```

## Links

- **Website**: https://facialharmonyai.com
- **Pricing**: https://facialharmonyai.com/#pricing
- **Features**: https://facialharmonyai.com/#features
- **FAQ**: https://facialharmonyai.com/#faq
- **GitHub**: https://github.com/bbwdadfg/facialharmonyai-site-kit

## License

MIT
