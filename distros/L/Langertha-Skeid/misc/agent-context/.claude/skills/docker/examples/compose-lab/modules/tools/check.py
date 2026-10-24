import json
import urllib.request

with urllib.request.urlopen('http://app:8080/health', timeout=5) as response:
    body = json.load(response)
if body.get('status') != 'ok':
    raise SystemExit('Application health check failed')
print('Service-name DNS, container port, HTTP response, and application status passed.')
