package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"runtime"
	"strconv"
)

func main() {
	runtime.GOMAXPROCS(1)

	port := os.Getenv("BENCH_PORT")
	if port == "" {
		fmt.Fprintln(os.Stderr, "BENCH_PORT is required")
		os.Exit(2)
	}

	responseBytes := 32
	if value := os.Getenv("BENCH_RESPONSE_BYTES"); value != "" {
		n, err := strconv.Atoi(value)
		if err != nil || n < 0 {
			fmt.Fprintln(os.Stderr, "BENCH_RESPONSE_BYTES must be a non-negative integer")
			os.Exit(2)
		}
		responseBytes = n
	}

	payload := make([]byte, responseBytes)
	for i := range payload {
		payload[i] = 'x'
	}
	contentLength := strconv.Itoa(len(payload))

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Body != nil {
			_, _ = io.Copy(io.Discard, r.Body)
			_ = r.Body.Close()
		}

		w.Header().Set("Content-Type", "application/octet-stream")
		w.Header().Set("Content-Length", contentLength)
		w.WriteHeader(http.StatusOK)
		if len(payload) != 0 {
			_, _ = w.Write(payload)
		}
	})

	server := &http.Server{
		Addr:    "127.0.0.1:" + port,
		Handler: handler,
	}
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
