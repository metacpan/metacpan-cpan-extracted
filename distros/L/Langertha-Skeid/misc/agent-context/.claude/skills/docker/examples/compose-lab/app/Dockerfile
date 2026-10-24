# syntax=docker/dockerfile:1
FROM python:3.13-slim
# This teaching tag floats within a minor version. Pin a reviewed digest for releases.
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
RUN mkdir -p /state && chown 10001:10001 /state /app
COPY --chown=10001:10001 app.py /app/app.py
USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=5 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=2).close()"]
CMD ["python", "/app/app.py"]
